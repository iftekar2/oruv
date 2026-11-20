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

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        logger.info("[OruvMonitor] intervalDidStart for \(activity.rawValue)")

        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "oruv_last_monitor_trigger_time")
        sharedDefaults?.set("intervalDidStart: \(activity.rawValue)", forKey: "oruv_last_monitor_trigger_name")

        // 1. If it's a schedule activity, check if today is an active day
        if activity.rawValue.starts(with: "oruv.schedule.") {
            let scheduleId = String(activity.rawValue.dropFirst("oruv.schedule.".count))
            if let schedulesData = sharedDefaults?.data(forKey: "oruv_stored_schedules"),
               let schedules = try? JSONDecoder().decode([StoredSchedule].self, from: schedulesData),
               let schedule = schedules.first(where: { $0.id == scheduleId }) {
                let weekday = Calendar.current.component(.weekday, from: Date())
                if !schedule.isScheduled(forWeekday: weekday) {
                    logger.info("[OruvMonitor] Schedule \(scheduleId) is not active for weekday \(weekday). Skipping.")
                    return
                }
            }
        }

        // 2. Check if currently on a mindful break
        let breakEndTimestamp = sharedDefaults?.double(forKey: "oruv_mindful_break_end_time") ?? 0
        if breakEndTimestamp > 0 {
            let breakEndDate = Date(timeIntervalSince1970: breakEndTimestamp)
            if Date() < breakEndDate {
                logger.info("[OruvMonitor] Mindful break is active until \(breakEndDate). Skipping shield.")
                return
            } else {
                sharedDefaults?.removeObject(forKey: "oruv_mindful_break_end_time")
            }
        }

        // 3. Apply shield immediately!
        applyShield()
        sharedDefaults?.set(true, forKey: "oruv_is_shield_active")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logger.info("[OruvMonitor] intervalDidEnd for \(activity.rawValue)")

        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "oruv_last_monitor_trigger_time")
        sharedDefaults?.set("intervalDidEnd: \(activity.rawValue)", forKey: "oruv_last_monitor_trigger_name")

        // Check if any other schedule is still active right now
        let shouldStayBlocked = shouldShieldBeActive()
        if shouldStayBlocked {
            logger.info("[OruvMonitor] Another schedule is still active. Keeping shield.")
            applyShield()
            sharedDefaults?.set(true, forKey: "oruv_is_shield_active")
        } else {
            logger.info("[OruvMonitor] No other schedules running. Clearing shield.")
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
        let sharedDefaults = UserDefaults(suiteName: appGroupId)

        // 1. Check if currently on a mindful break
        let breakEndTimestamp = sharedDefaults?.double(forKey: "oruv_mindful_break_end_time") ?? 0
        if breakEndTimestamp > 0 {
            let breakEndDate = Date(timeIntervalSince1970: breakEndTimestamp)
            if date < breakEndDate {
                return false
            } else {
                sharedDefaults?.removeObject(forKey: "oruv_mindful_break_end_time")
            }
        }

        // 2. Read stored schedules
        guard let schedulesData = sharedDefaults?.data(forKey: "oruv_stored_schedules"),
              let schedules = try? JSONDecoder().decode([StoredSchedule].self, from: schedulesData) else {
            return false
        }

        // 3. Check if any active schedule is currently running right now
        return schedules.contains { $0.isCurrentlyRunning(at: date) }
    }

    private func applyShield() {
        guard let data = UserDefaults(suiteName: appGroupId)?.data(forKey: storageKey),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
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
