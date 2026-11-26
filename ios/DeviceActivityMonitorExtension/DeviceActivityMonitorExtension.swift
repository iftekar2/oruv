import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation
import os.log

private let logger = Logger(subsystem: "app.iftekarhossain.oruv", category: "DeviceActivityMonitor")

public struct StoredSchedule: Codable {
    public let id: String
    public let title: String
    public let startHour: Int
    public let startMinute: Int
    public let endHour: Int
    public let endMinute: Int
    public let activeDays: [String]
    public let isActive: Bool

    public init(
        id: String,
        title: String,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        activeDays: [String],
        isActive: Bool
    ) {
        self.id = id
        self.title = title
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.activeDays = activeDays
        self.isActive = isActive
    }

    public func isScheduled(forWeekday weekday: Int) -> Bool {
        if activeDays.isEmpty { return true }
        let key: String
        switch weekday {
        case 1: key = "S2" // Sunday
        case 2: key = "M"  // Monday
        case 3: key = "T"  // Tuesday
        case 4: key = "W"  // Wednesday
        case 5: key = "T2" // Thursday
        case 6: key = "F"  // Friday
        case 7: key = "S"  // Saturday
        default: key = "M"
        }
        return activeDays.contains(key)
    }

    public func isCurrentlyRunning(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard isActive else { return false }

        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let nowMins = hour * 60 + minute

        let startMins = startHour * 60 + startMinute
        let endMins = endHour * 60 + endMinute

        if startMins <= endMins {
            guard isScheduled(forWeekday: weekday) else { return false }
            return nowMins >= startMins && nowMins < endMins
        } else {
            // Overnight schedule (e.g. 10:00 PM to 7:00 AM)
            // Evening part: started today
            if nowMins >= startMins {
                return isScheduled(forWeekday: weekday)
            }
            // Morning part: started yesterday evening or today
            if nowMins < endMins {
                let yesterdayWeekday = weekday == 1 ? 7 : weekday - 1
                return isScheduled(forWeekday: yesterdayWeekday) || isScheduled(forWeekday: weekday)
            }
            return false
        }
    }
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let appGroupId = "group.app.iftekarhossain.oruv"
    private let storageKey = "oruv_family_activity_selection"
    private let selectionFileName = "family_activity_selection.plist"
    private let schedulesFileName = "stored_schedules.json"
    private let mindfulBreakFileName = "mindful_break_state.json"

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        let rawName = activity.rawValue
        logger.info("[OruvMonitor] intervalDidStart for \(rawName)")

        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "oruv_last_monitor_trigger_time")
        sharedDefaults?.set("intervalDidStart: \(rawName)", forKey: "oruv_last_monitor_trigger_name")

        // Handle Mindful Break expiry monitor
        if rawName == "oruv.mindful_break.end" {
            clearMindfulBreakState()
            evaluateAndApplyShield(trigger: "mindfulBreakEnd: \(rawName)")
            return
        }

        // Only handle schedule monitors (ignore oruv.daily.activity report monitor)
        guard rawName.hasPrefix("oruv.schedule.") else { return }

        // If this is a short-schedule (<15 min) end trigger ("oruv.schedule.end.<id>.."),
        // evaluate whether any schedule is still active and clear/apply accordingly.
        if rawName.hasPrefix("oruv.schedule.end.") {
            evaluateAndApplyShield(trigger: "shortScheduleEnd: \(rawName)")
            return
        }

        // 1. Check if today is an active day for this schedule
        let scheduleId = extractScheduleId(from: rawName, prefix: "oruv.schedule.")
        let schedules = loadStoredSchedules()
        if let schedule = schedules.first(where: { $0.id == scheduleId }) {
            guard schedule.isActive else { return }
            let now = Date()
            let weekday = Calendar.current.component(.weekday, from: now)
            if !schedule.isScheduled(forWeekday: weekday) && !schedule.isCurrentlyRunning(at: now) {
                logger.info("[OruvMonitor] Schedule \(scheduleId) is not active for weekday \(weekday). Skipping.")
                return
            }
        } else if !schedules.isEmpty {
            // Schedule ID no longer exists in stored schedules; evaluate overall state
            evaluateAndApplyShield(trigger: "unknownScheduleStart: \(rawName)")
            return
        }

        // 2. Check if currently on a mindful break
        if isMindfulBreakActive() {
            logger.info("[OruvMonitor] Mindful break is currently active. Skipping shield.")
            return
        }

        // 3. Apply shield immediately
        applyShield()
        sharedDefaults?.set(true, forKey: "oruv_is_shield_active")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        let rawName = activity.rawValue
        logger.info("[OruvMonitor] intervalDidEnd for \(rawName)")

        if rawName == "oruv.mindful_break.end" {
            evaluateAndApplyShield(trigger: "mindfulBreakIntervalEnd: \(rawName)")
            return
        }

        // Only handle schedule monitors (ignore oruv.daily.activity report monitor)
        guard rawName.hasPrefix("oruv.schedule.") else { return }

        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "oruv_last_monitor_trigger_time")
        sharedDefaults?.set("intervalDidEnd: \(rawName)", forKey: "oruv_last_monitor_trigger_name")

        // Check if any schedule is still active right now before clearing
        let shouldStayBlocked = shouldShieldBeActive()
        if shouldStayBlocked {
            logger.info("[OruvMonitor] A schedule is still active. Keeping shield.")
            applyShield()
            sharedDefaults?.set(true, forKey: "oruv_is_shield_active")
        } else {
            logger.info("[OruvMonitor] No schedules currently running. Clearing shield.")
            clearShield()
            sharedDefaults?.set(false, forKey: "oruv_is_shield_active")
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }

    private func extractScheduleId(from rawActivityName: String, prefix: String) -> String {
        let stripped = String(rawActivityName.dropFirst(prefix.count))
        if let range = stripped.range(of: "..") {
            return String(stripped[..<range.lowerBound])
        }
        return stripped
    }

    private func readAppGroupData(named fileName: String) -> Data? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            return nil
        }
        let fileURL = containerURL.appendingPathComponent(fileName)
        var resultData: Data? = nil
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: nil) { targetURL in
            resultData = try? Data(contentsOf: targetURL)
        }
        return resultData
    }

    private func removeAppGroupFile(named fileName: String) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            return
        }
        let fileURL = containerURL.appendingPathComponent(fileName)
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(writingItemAt: fileURL, options: .forDeleting, error: nil) { targetURL in
            try? FileManager.default.removeItem(at: targetURL)
        }
    }

    private func loadStoredSchedules() -> [StoredSchedule] {
        if let fileData = readAppGroupData(named: schedulesFileName),
           let schedules = try? JSONDecoder().decode([StoredSchedule].self, from: fileData) {
            return schedules
        }
        if let schedulesData = UserDefaults(suiteName: appGroupId)?.data(forKey: "oruv_stored_schedules"),
           let schedules = try? JSONDecoder().decode([StoredSchedule].self, from: schedulesData) {
            return schedules
        }
        return []
    }

    private func loadActivitySelection() -> FamilyActivitySelection? {
        if let fileData = readAppGroupData(named: selectionFileName),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: fileData) {
            return selection
        }
        if let data = UserDefaults(suiteName: appGroupId)?.data(forKey: storageKey),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            return selection
        }
        return nil
    }

    private func isMindfulBreakActive(at date: Date = Date()) -> Bool {
        if let data = readAppGroupData(named: mindfulBreakFileName),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ts = (json["breakEndTime"] as? NSNumber)?.doubleValue ?? (json["breakEndTime"] as? Double),
           ts > 0 {
            let breakEndDate = Date(timeIntervalSince1970: ts)
            if date < breakEndDate {
                return true
            } else {
                clearMindfulBreakState()
                return false
            }
        }

        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        let breakEndTimestamp = sharedDefaults?.double(forKey: "oruv_mindful_break_end_time") ?? 0
        if breakEndTimestamp > 0 {
            let breakEndDate = Date(timeIntervalSince1970: breakEndTimestamp)
            if date < breakEndDate {
                return true
            } else {
                clearMindfulBreakState()
                return false
            }
        }
        return false
    }

    private func clearMindfulBreakState() {
        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        sharedDefaults?.removeObject(forKey: "oruv_mindful_break_end_time")
        removeAppGroupFile(named: mindfulBreakFileName)
    }

    private func evaluateAndApplyShield(trigger: String) {
        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "oruv_last_monitor_trigger_time")
        sharedDefaults?.set(trigger, forKey: "oruv_last_monitor_trigger_name")

        let shouldBlock = shouldShieldBeActive()
        logger.info("[OruvMonitor] evaluateAndApplyShield: shouldBlock=\(shouldBlock)")

        if shouldBlock {
            applyShield()
            sharedDefaults?.set(true, forKey: "oruv_is_shield_active")
        } else {
            clearShield()
            sharedDefaults?.set(false, forKey: "oruv_is_shield_active")
        }
    }

    private func shouldShieldBeActive(at date: Date = Date()) -> Bool {
        // 1. Check if currently on a mindful break
        if isMindfulBreakActive(at: date) {
            return false
        }

        // 2. Read stored schedules from App Group file (with UserDefaults fallback)
        let schedules = loadStoredSchedules()
        guard !schedules.isEmpty else {
            return false
        }

        // 3. Check if any active schedule is currently running right now
        return schedules.contains { $0.isCurrentlyRunning(at: date) }
    }

    private func applyShield() {
        guard let selection = loadActivitySelection() else {
            logger.warning("[OruvMonitor] No saved selection found in App Group")
            return
        }

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        logger.info("[OruvMonitor] Successfully applied shield tokens")
    }

    private func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        logger.info("[OruvMonitor] Successfully cleared shields")
    }
}
