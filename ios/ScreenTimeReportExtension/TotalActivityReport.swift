import DeviceActivity
import ExtensionKit
import FamilyControls
@preconcurrency import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let dailyScreenTime = Self("DailyScreenTime")
    static let insightsScreenTime = Self("InsightsScreenTime")
    static let anchorTimeSaved = Self("AnchorTimeSaved")
    static let totalActivity = Self("Total Activity")
}

struct AnchorTimeSavedConfiguration: Sendable {
    let timeText: String
    let label: String
    let isSavingTime: Bool
}

struct AppActivityItem: Identifiable, Sendable {
    let id: String
    let token: ApplicationToken
    let displayName: String
    let durationMinutes: Int

    var formattedDuration: String {
        Self.formatMinutes(durationMinutes)
    }

    static func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
    }
}

struct DailyScreenTimeConfiguration: Sendable {
    let totalMinutes: Int
    let apps: [AppActivityItem]

    var formattedTotalDuration: String {
        AppActivityItem.formatMinutes(totalMinutes)
    }
}

struct InsightsAppActivityItem: Identifiable, Sendable {
    let id: String
    let token: ApplicationToken
    let displayName: String
    let bundleId: String
    let categoryName: String
    let durationMinutes: Int
    let isDistracting: Bool
    let isOruv: Bool
    let isBrowser: Bool

    var formattedDuration: String {
        AppActivityItem.formatMinutes(durationMinutes)
    }
}

struct WeekdayScreenTimeItem: Identifiable, Sendable {
    let id: Int // 0 = Sunday ... 6 = Saturday
    let dayLabel: String
    let totalMinutes: Int
    let isToday: Bool
    let isFuture: Bool
}

struct InsightsScreenTimeConfiguration: Sendable {
    let totalMinutes: Int
    let distractingMinutes: Int
    let otherMinutes: Int
    let distractedPercentage: Int
    let timeSavedText: String
    let timeSavedLabel: String
    let isSavingTime: Bool
    let pickupsPerHour: Int
    let distractingApps: [InsightsAppActivityItem]
    let otherApps: [InsightsAppActivityItem]

    let weekTotalMinutes: Int
    let weekDailyAverageMinutes: Int
    let weekDistractingMinutes: Int
    let weekOtherMinutes: Int
    let weekDistractedPercentage: Int
    let weekTimeSavedText: String
    let weekTimeSavedLabel: String
    let weekIsSavingTime: Bool
    let weekHasLastWeekData: Bool
    let weekLastWeekText: String
    let weekLastWeekLabel: String
    let weekIsUnderLastWeek: Bool
    let weekDays: [WeekdayScreenTimeItem]
    let weekDistractingApps: [InsightsAppActivityItem]
    let weekOtherApps: [InsightsAppActivityItem]

    var formattedTotalDuration: String {
        AppActivityItem.formatMinutes(totalMinutes)
    }

    var formattedDistractingDuration: String {
        AppActivityItem.formatMinutes(distractingMinutes)
    }

    var formattedOtherDuration: String {
        AppActivityItem.formatMinutes(otherMinutes)
    }

    var formattedWeekDailyAverage: String {
        AppActivityItem.formatMinutes(weekDailyAverageMinutes)
    }

    var formattedWeekTotalDuration: String {
        AppActivityItem.formatMinutes(weekTotalMinutes)
    }

    var formattedWeekDistractingDuration: String {
        AppActivityItem.formatMinutes(weekDistractingMinutes)
    }

    var formattedWeekOtherDuration: String {
        AppActivityItem.formatMinutes(weekOtherMinutes)
    }
}

enum AppCategorizer {
    private static let nonDistractingKeywords: [String] = [
        "oruv",
        "safari", "mobilesafari", "chrome", "firefox", "brave", "duckduckgo", "arc", "opera",
        "preferences", "settings", "mobilephone", "phone", "mobilesms", "messages", "facetime",
        "mobilemail", "mail", "gmail", "outlook", "spark", "superhuman",
        "mobilecal", "calendar", "mobilenotes", "notes", "reminders", "clock", "mobiletimer",
        "calculator", "weather", "maps", "googlemaps", "waze", "camera", "mobileslideshow", "photos",
        "passbook", "wallet", "health", "fitness", "files", "documents", "shortcuts", "findmy",
        "compass", "measure", "magnifier", "translate", "voicememos", "contacts", "appstore",
        "testflight", "passwords", "authenticator", "podcasts", "ibooks", "books", "kindle", "audible",
        "snkrs", "nike", "amazon", "ebay", "etsy", "target", "walmart", "shopify", "shop",
        "uber", "lyft", "doordash", "ubereats", "grubhub", "instacart",
        "slack", "teams", "zoom", "webex", "notion", "obsidian", "linear", "github", "gitlab",
        "figma", "canva", "chatgpt", "openai", "claude", "anthropic", "gemini",
        "docs", "sheets", "slides", "drive", "word", "excel", "powerpoint", "onedrive", "dropbox",
        "todoist", "things", "trello", "asana", "jira", "duolingo", "anki", "canvas", "coursera", "khan"
    ]

    private static let distractingKeywords: [String] = [
        // Social Media
        "tiktok", "musically", "aweme", "instagram", "burbn", "snapchat", "picaboo",
        "twitter", "tweetie", "atebits", "reddit", "facebook", "threads", "barcelona",
        "discord", "pinterest", "tumblr", "bereal", "bluesky", "bsky", "mastodon",
        "yikyak", "fizz", "linkedin", "wechat", "kik", "telegram", "whatsapp", "messenger",
        "hinge", "tinder", "bumble",
        // Video & Streaming Entertainment
        "youtube", "netflix", "twitch", "hulu", "disney", "hbomax", "wbd.stream",
        "primevideo", "aiv", "crunchyroll", "peacock", "paramount", "tubi", "plutotv",
        "kick", "9gag", "ifunny", "bilibili", "dailymotion", "webtoon", "letterboxd",
        // Games & Gaming Platforms
        "roblox", "minecraft", "brawlstars", "clashroyale", "clashofclans", "supercell",
        "candycrush", "king.", "genshin", "hoyoverse", "honkai", "pubg", "callofduty",
        "activision", "ea.", "fifa", "madden", "nba2k", "amongus", "innersloth",
        "subwaysurfers", "kiloo", "sybo", "pokemon", "niantic", "monopoly", "scopely",
        "royalmatch", "dreamgames", "chess", "steam", "playstation", "xbox", "epicgames",
        "fortnite", "riotgames", "hearthstone", "blizzard", "zynga", "rovio", "angrybirds",
        "miniclip", "playrix", "gardenscapes", "homescapes", "blockblast", "balatro", "wordle"
    ]

    static func isOruvApp(name: String, bundleId: String) -> Bool {
        let lowerName = name.lowercased()
        let lowerBundle = bundleId.lowercased()
        return lowerName.contains("oruv") || lowerBundle.contains("oruv")
    }

    static func isBrowserApp(name: String, bundleId: String) -> Bool {
        let lowerName = name.lowercased()
        let lowerBundle = bundleId.lowercased()
        let browsers = ["safari", "chrome", "firefox", "brave", "arc", "duckduckgo", "opera"]
        return browsers.contains { lowerName.contains($0) || lowerBundle.contains($0) }
    }

    static func isDistracting(
        token: ApplicationToken,
        name: String,
        bundleId: String,
        categoryName: String,
        categoryToken: ActivityCategoryToken?,
        selectedAppTokens: Set<ApplicationToken>,
        selectedCategoryTokens: Set<ActivityCategoryToken>
    ) -> Bool {
        // 1. Oruv itself is always in Other Apps
        if isOruvApp(name: name, bundleId: bundleId) {
            return false
        }

        // 2. Explicitly selected by the user in Oruv's shield picker
        if selectedAppTokens.contains(token) {
            return true
        }

        let lowerName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerBundle = bundleId.lowercased()
        let lowerCat = categoryName.lowercased()

        // 3. Known Social Media, Games, Short-form Video & Streaming apps
        if lowerName == "x" {
            return true
        }
        for kw in distractingKeywords {
            if lowerName.contains(kw) || lowerBundle.contains(kw) {
                return true
            }
        }

        // 4. Known non-distracting system utilities, browsers, shopping & productivity apps
        for kw in nonDistractingKeywords {
            if lowerName.contains(kw) || lowerBundle.contains(kw) {
                return false
            }
        }

        // 5. User-selected category in Oruv's shield picker
        if let catToken = categoryToken, selectedCategoryTokens.contains(catToken) {
            return true
        }

        // 6. Apple's system ActivityCategory classification
        if lowerCat.contains("game") ||
           lowerCat.contains("social") ||
           lowerCat.contains("entertainment") {
            return true
        }

        return false
    }
}

nonisolated struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .dailyScreenTime
    let content: (DailyScreenTimeConfiguration) -> TotalActivityView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> DailyScreenTimeConfiguration {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        var todayTotalSeconds: TimeInterval = 0
        var yesterdayTotalSeconds: TimeInterval = 0
        var appDurations: [ApplicationToken: (name: String, seconds: TimeInterval)] = [:]

        for await activityData in data {
            for await segment in activityData.activitySegments {
                let isToday = segment.dateInterval.end > startOfToday
                if isToday {
                    todayTotalSeconds += segment.totalActivityDuration
                    for await categoryActivity in segment.categories {
                        for await appActivity in categoryActivity.applications {
                            let duration = appActivity.totalActivityDuration
                            guard duration >= 60, let token = appActivity.application.token else { continue }
                            let name = appActivity.application.localizedDisplayName ?? "App"
                            let existing = appDurations[token]?.seconds ?? 0
                            appDurations[token] = (name: name, seconds: existing + duration)
                        }
                    }
                } else {
                    yesterdayTotalSeconds += segment.totalActivityDuration
                }
            }
        }

        let sortedItems: [AppActivityItem] = appDurations
            .map { token, info in
                AppActivityItem(
                    id: "\(token.hashValue)",
                    token: token,
                    displayName: info.name,
                    durationMinutes: max(1, Int(info.seconds / 60))
                )
            }
            .sorted { $0.durationMinutes > $1.durationMinutes }
            .prefix(5)
            .map { $0 }

        let totalMinutes = max(0, Int(todayTotalSeconds / 60))
        let yesterdayMinutes = max(0, Int(yesterdayTotalSeconds / 60))

        let appGroupId = "group.app.iftekarhossain.oruv"
        let sharedDefaults = UserDefaults(suiteName: appGroupId)

        var baselineDailyMinutes = 300
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            let fileURL = containerURL.appendingPathComponent("insights_metrics.json")
            if let jsonData = try? Data(contentsOf: fileURL),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if let base = json["baselineMinutes"] as? Int, base > 0 {
                    baselineDailyMinutes = base
                }
            }
        }

        let cachedInsightsYesterday = sharedDefaults?.integer(forKey: "oruv_insights_yesterday_minutes") ?? 0
        let realYesterday = yesterdayMinutes > 0 ? yesterdayMinutes : (cachedInsightsYesterday > 0 ? cachedInsightsYesterday : 0)
        let effectiveYesterdayMinutes = realYesterday > 0 ? realYesterday : baselineDailyMinutes
        let diffMinutes = effectiveYesterdayMinutes - totalMinutes
        let isSavingTime = diffMinutes >= 0
        let absDiffMinutes = abs(diffMinutes)
        var timeSavedText = AppActivityItem.formatMinutes(absDiffMinutes)
        var timeSavedLabel = isSavingTime ? "On Track to Save" : "Over Yest."

        var isSaving = isSavingTime
        if let insightsText = sharedDefaults?.string(forKey: "oruv_insights_time_saved_text"), !insightsText.isEmpty,
           let insightsLabel = sharedDefaults?.string(forKey: "oruv_insights_time_saved_label"), !insightsLabel.isEmpty {
            timeSavedText = insightsText
            timeSavedLabel = insightsLabel
            if let savedIsSaving = sharedDefaults?.object(forKey: "oruv_insights_is_saving_time") as? Bool {
                isSaving = savedIsSaving
            } else {
                isSaving = !insightsLabel.lowercased().contains("over")
            }
        }

        sharedDefaults?.set(totalMinutes, forKey: "oruv_daily_total_minutes")
        sharedDefaults?.set(effectiveYesterdayMinutes, forKey: "oruv_yesterday_total_minutes")
        sharedDefaults?.set(timeSavedText, forKey: "oruv_time_saved_text")
        sharedDefaults?.set(timeSavedLabel, forKey: "oruv_time_saved_label")
        sharedDefaults?.set(isSaving, forKey: "oruv_is_saving_time")
        sharedDefaults?.set(absDiffMinutes, forKey: "oruv_diff_minutes")

        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            let statsURL = containerURL.appendingPathComponent("screen_time_stats.json")
            let statsDict: [String: Any] = [
                "totalMinutes": totalMinutes,
                "yesterdayTotalMinutes": effectiveYesterdayMinutes,
                "timeSavedText": timeSavedText,
                "timeSavedLabel": timeSavedLabel,
                "isSavingTime": isSaving,
                "diffMinutes": absDiffMinutes
            ]
            if let json = try? JSONSerialization.data(withJSONObject: statsDict, options: []) {
                let coordinator = NSFileCoordinator(filePresenter: nil)
                coordinator.coordinate(writingItemAt: statsURL, options: .forReplacing, error: nil) { targetURL in
                    try? json.write(to: targetURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                    var mutableURL = targetURL
                    var values = URLResourceValues()
                    values.isExcludedFromBackup = true
                    try? mutableURL.setResourceValues(values)
                }
            }
        }

        let appsPayload: [[String: Any]] = sortedItems.map { item in
            [
                "id": item.id,
                "name": item.displayName,
                "durationMinutes": item.durationMinutes,
                "isDistracting": true
            ]
        }
        sharedDefaults?.set(appsPayload, forKey: "oruv_daily_apps")
        sharedDefaults?.synchronize()

        return DailyScreenTimeConfiguration(
            totalMinutes: totalMinutes,
            apps: sortedItems
        )
    }
}

nonisolated struct InsightsActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .insightsScreenTime
    let content: (InsightsScreenTimeConfiguration) -> InsightsActivityView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> InsightsScreenTimeConfiguration {
        let appGroupId = "group.app.iftekarhossain.oruv"
        let sharedDefaults = UserDefaults(suiteName: appGroupId)

        var selectedAppTokens: Set<ApplicationToken> = []
        var selectedCategoryTokens: Set<ActivityCategoryToken> = []
        if let selData = sharedDefaults?.data(forKey: "oruv_family_activity_selection"),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: selData) {
            selectedAppTokens = selection.applicationTokens
            selectedCategoryTokens = selection.categoryTokens
        }

        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: now) // 1 = Sun ... 7 = Sat
        let todayIndex = max(0, min(6, weekday - 1))
        let startOfWeekSunday = calendar.date(byAdding: .day, value: -todayIndex, to: startOfToday) ?? startOfToday
        let startOfLastWeekSunday = calendar.date(byAdding: .day, value: -7, to: startOfWeekSunday) ?? startOfWeekSunday.addingTimeInterval(-7 * 86400)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday.addingTimeInterval(-86400)

        var todayTotalSeconds: TimeInterval = 0
        var yesterdayTotalSeconds: TimeInterval = 0
        var todayPickups: Int = 0
        var earliestPickup: Date? = nil

        var weekDaySeconds: [TimeInterval] = Array(repeating: 0, count: 7)
        var weekDayAppSeconds: [TimeInterval] = Array(repeating: 0, count: 7)
        var lastWeekDaySeconds: [TimeInterval] = Array(repeating: 0, count: 7)
        var lastWeekDayAppSeconds: [TimeInterval] = Array(repeating: 0, count: 7)

        struct RawAppAccumulator {
            var name: String
            var bundleId: String
            var categoryName: String
            var categoryToken: ActivityCategoryToken?
            var seconds: TimeInterval
            var pickups: Int
        }

        var todayAppMap: [ApplicationToken: RawAppAccumulator] = [:]
        var weekAppMap: [ApplicationToken: RawAppAccumulator] = [:]

        func accumulateApp(
            into map: inout [ApplicationToken: RawAppAccumulator],
            token: ApplicationToken,
            name: String,
            bundleId: String,
            catName: String,
            catToken: ActivityCategoryToken?,
            duration: TimeInterval,
            pickups: Int
        ) {
            if var existing = map[token] {
                if (existing.name == "App" || existing.name.isEmpty) && !name.isEmpty {
                    existing.name = name
                }
                if existing.bundleId.isEmpty && !bundleId.isEmpty {
                    existing.bundleId = bundleId
                }
                if existing.categoryName.isEmpty && !catName.isEmpty {
                    existing.categoryName = catName
                }
                if existing.categoryToken == nil && catToken != nil {
                    existing.categoryToken = catToken
                }
                existing.seconds += duration
                existing.pickups += pickups
                map[token] = existing
            } else {
                map[token] = RawAppAccumulator(
                    name: name,
                    bundleId: bundleId,
                    categoryName: catName,
                    categoryToken: catToken,
                    seconds: duration,
                    pickups: pickups
                )
            }
        }

        for await activityData in data {
            for await segment in activityData.activitySegments {
                let segDuration = max(0, segment.dateInterval.duration)
                let segMidpoint = segment.dateInterval.start.addingTimeInterval(segDuration * 0.5)
                let segDayStart = calendar.startOfDay(for: segMidpoint)
                let isToday = segDayStart >= startOfToday || segment.dateInterval.end > startOfToday
                let isYesterday = !isToday && segDayStart == startOfYesterday
                let isInCurrentWeek = segDayStart >= startOfWeekSunday && segDayStart <= startOfToday
                let isInLastWeek = segDayStart >= startOfLastWeekSunday && segDayStart < startOfWeekSunday
                let segDayIdx = max(0, min(6, calendar.component(.weekday, from: segDayStart) - 1))

                if isToday {
                    todayTotalSeconds += segment.totalActivityDuration
                    todayPickups += segment.totalPickupsWithoutApplicationActivity
                    if let fp = segment.firstPickup {
                        if earliestPickup == nil || fp < earliestPickup! {
                            earliestPickup = fp
                        }
                    }
                } else if isYesterday {
                    yesterdayTotalSeconds += segment.totalActivityDuration
                }

                if isInCurrentWeek && segDayIdx <= todayIndex {
                    weekDaySeconds[segDayIdx] += segment.totalActivityDuration
                } else if isInLastWeek {
                    lastWeekDaySeconds[segDayIdx] += segment.totalActivityDuration
                }

                for await categoryActivity in segment.categories {
                    let catName = categoryActivity.category.localizedDisplayName ?? ""
                    let catToken = categoryActivity.category.token

                    for await appActivity in categoryActivity.applications {
                        let duration = appActivity.totalActivityDuration
                        let pickups = appActivity.numberOfPickups

                        if isToday {
                            todayPickups += pickups
                        }
                        if isInCurrentWeek && segDayIdx <= todayIndex {
                            weekDayAppSeconds[segDayIdx] += duration
                        } else if isInLastWeek {
                            lastWeekDayAppSeconds[segDayIdx] += duration
                        }

                        guard duration > 0, let token = appActivity.application.token else { continue }
                        let name = appActivity.application.localizedDisplayName ?? "App"
                        let bundleId = appActivity.application.bundleIdentifier ?? ""

                        if isToday && duration >= 60 {
                            accumulateApp(
                                into: &todayAppMap,
                                token: token,
                                name: name,
                                bundleId: bundleId,
                                catName: catName,
                                catToken: catToken,
                                duration: duration,
                                pickups: pickups
                            )
                        }

                        if isInCurrentWeek && segDayIdx <= todayIndex {
                            accumulateApp(
                                into: &weekAppMap,
                                token: token,
                                name: name,
                                bundleId: bundleId,
                                catName: catName,
                                catToken: catToken,
                                duration: duration,
                                pickups: pickups
                            )
                        }
                    }
                }
            }
        }

        func categorizeApps(
            from map: [ApplicationToken: RawAppAccumulator]
        ) -> (distracting: [InsightsAppActivityItem], other: [InsightsAppActivityItem]) {
            var distracting: [InsightsAppActivityItem] = []
            var other: [InsightsAppActivityItem] = []

            for (token, info) in map {
                guard info.seconds >= 60 else { continue }
                let mins = max(1, Int(info.seconds / 60))
                let isOruv = AppCategorizer.isOruvApp(name: info.name, bundleId: info.bundleId)
                let isBrowser = AppCategorizer.isBrowserApp(name: info.name, bundleId: info.bundleId)
                let isDistracting = AppCategorizer.isDistracting(
                    token: token,
                    name: info.name,
                    bundleId: info.bundleId,
                    categoryName: info.categoryName,
                    categoryToken: info.categoryToken,
                    selectedAppTokens: selectedAppTokens,
                    selectedCategoryTokens: selectedCategoryTokens
                )

                let item = InsightsAppActivityItem(
                    id: "\(token.hashValue)",
                    token: token,
                    displayName: info.name,
                    bundleId: info.bundleId,
                    categoryName: info.categoryName,
                    durationMinutes: mins,
                    isDistracting: isDistracting,
                    isOruv: isOruv,
                    isBrowser: isBrowser
                )

                if isDistracting {
                    distracting.append(item)
                } else {
                    other.append(item)
                }
            }

            distracting.sort { $0.durationMinutes > $1.durationMinutes }
            other.sort { $0.durationMinutes > $1.durationMinutes }
            return (distracting, other)
        }

        let (distractingItems, otherItems) = categorizeApps(from: todayAppMap)
        let (weekDistractingItems, weekOtherItems) = categorizeApps(from: weekAppMap)

        let distractingMins = distractingItems.reduce(0) { $0 + $1.durationMinutes }
        let otherMins = otherItems.reduce(0) { $0 + $1.durationMinutes }
        let rawTodayMins = max(0, Int(todayTotalSeconds / 60))
        let totalMins = max(rawTodayMins, distractingMins + otherMins)
        let yesterdayMins = max(0, Int(yesterdayTotalSeconds / 60))

        // 1. % DISTRACTED (Day)
        let pctDistracted: Int
        if totalMins > 0 {
            pctDistracted = min(100, max(0, Int(round(Double(distractingMins) / Double(totalMins) * 100.0))))
        } else {
            pctDistracted = 0
        }

        // 2. PICKUPS / HR (Day)
        let sevenAM = startOfToday.addingTimeInterval(7 * 3600)
        let referenceStart: Date
        if let fp = earliestPickup {
            referenceStart = fp
        } else if now > sevenAM {
            referenceStart = sevenAM
        } else {
            referenceStart = startOfToday
        }
        let elapsedHours = max(1.0, now.timeIntervalSince(referenceStart) / 3600.0)
        let pickupsPerHour: Int
        if todayPickups > 0 {
            pickupsPerHour = max(1, Int(round(Double(todayPickups) / elapsedHours)))
        } else if totalMins > 0 {
            pickupsPerHour = max(1, Int(round(Double(todayAppMap.count) / elapsedHours)))
        } else {
            pickupsPerHour = 0
        }

        // 3. TIME SAVED vs YESTERDAY (Day)
        var baselineDailyMinutes = 300 // 5h default daily distraction/screen baseline fallback
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            let fileURL = containerURL.appendingPathComponent("insights_metrics.json")
            if let jsonData = try? Data(contentsOf: fileURL),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if let base = json["baselineMinutes"] as? Int, base > 0 {
                    baselineDailyMinutes = base
                }
            }
        }

        let effectiveYesterdayMinutes = yesterdayMins > 0 ? yesterdayMins : baselineDailyMinutes
        let diffMinutes = effectiveYesterdayMinutes - totalMins
        let isSavingTime = diffMinutes >= 0
        let absDiffMinutes = abs(diffMinutes)
        let timeSavedText = AppActivityItem.formatMinutes(absDiffMinutes)
        let timeSavedLabel = isSavingTime ? "On Track to Save" : "Over Yest."

        // 4. WEEK AGGREGATES (Sunday through Today only)
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
        var weekDays: [WeekdayScreenTimeItem] = []
        weekDays.reserveCapacity(7)
        for idx in 0..<7 {
            let isFuture = idx > todayIndex
            let isTodayIdx = idx == todayIndex
            let rawDayMins = max(0, Int(round(max(weekDaySeconds[idx], weekDayAppSeconds[idx]) / 60.0)))
            let dayMins = isFuture ? 0 : (isTodayIdx ? max(rawDayMins, totalMins) : rawDayMins)
            weekDays.append(
                WeekdayScreenTimeItem(
                    id: idx,
                    dayLabel: dayLabels[idx],
                    totalMinutes: dayMins,
                    isToday: isTodayIdx,
                    isFuture: isFuture
                )
            )
        }

        let weekDistractingMins = weekDistractingItems.reduce(0) { $0 + $1.durationMinutes }
        let weekOtherMins = weekOtherItems.reduce(0) { $0 + $1.durationMinutes }
        let sumOfWeekDays = weekDays.reduce(0) { $0 + $1.totalMinutes }
        let weekTotalMins = max(sumOfWeekDays, weekDistractingMins + weekOtherMins)

        let elapsedDaysCount = max(1, todayIndex + 1)
        let weekDailyAverageMins = Int(round(Double(weekTotalMins) / Double(elapsedDaysCount)))

        let weekPctDistracted: Int
        if weekTotalMins > 0 {
            weekPctDistracted = min(100, max(0, Int(round(Double(weekDistractingMins) / Double(weekTotalMins) * 100.0))))
        } else {
            weekPctDistracted = 0
        }

        let weekDiffMinutes = baselineDailyMinutes - weekDailyAverageMins
        let weekIsSavingTime = weekDiffMinutes >= 0
        let weekTimeSavedText = AppActivityItem.formatMinutes(abs(weekDiffMinutes))
        let weekTimeSavedLabel = weekIsSavingTime ? "Under Daily Goal" : "Over Daily Goal"

        var lastWeekDayMins: [Int] = Array(repeating: 0, count: 7)
        for idx in 0..<7 {
            lastWeekDayMins[idx] = max(0, Int(round(max(lastWeekDaySeconds[idx], lastWeekDayAppSeconds[idx]) / 60.0)))
        }
        let lastWeekSamePeriodMins = (0...todayIndex).reduce(0) { $0 + lastWeekDayMins[$1] }
        let lastWeekTotalMins = lastWeekDayMins.reduce(0, +)
        let lastWeekActiveDays = lastWeekDayMins.filter { $0 > 0 }.count

        let effectiveLastWeekMins: Int
        if lastWeekSamePeriodMins > 0 {
            effectiveLastWeekMins = lastWeekSamePeriodMins
        } else if lastWeekTotalMins > 0 && lastWeekActiveDays > 0 {
            effectiveLastWeekMins = Int(round(Double(lastWeekTotalMins) / Double(lastWeekActiveDays) * Double(elapsedDaysCount)))
        } else {
            effectiveLastWeekMins = 0
        }

        let weekHasLastWeekData = effectiveLastWeekMins > 0
        let lastWeekDiffMinutes = effectiveLastWeekMins - weekTotalMins
        let weekIsUnderLastWeek = lastWeekDiffMinutes >= 0
        let weekLastWeekText = weekHasLastWeekData ? AppActivityItem.formatMinutes(abs(lastWeekDiffMinutes)) : "--"
        let weekLastWeekLabel = weekHasLastWeekData
            ? (weekIsUnderLastWeek ? "Under Last Week" : "Over Last Week")
            : "vs Last Week"

        sharedDefaults?.set(totalMins, forKey: "oruv_daily_total_minutes")
        sharedDefaults?.set(effectiveYesterdayMinutes, forKey: "oruv_yesterday_total_minutes")
        sharedDefaults?.set(timeSavedText, forKey: "oruv_time_saved_text")
        sharedDefaults?.set(timeSavedLabel, forKey: "oruv_time_saved_label")
        sharedDefaults?.set(isSavingTime, forKey: "oruv_is_saving_time")
        sharedDefaults?.set(absDiffMinutes, forKey: "oruv_diff_minutes")

        // Dedicated Insights keys so Home page and widget can always access the exact Insights data
        sharedDefaults?.set(timeSavedText, forKey: "oruv_insights_time_saved_text")
        sharedDefaults?.set(timeSavedLabel, forKey: "oruv_insights_time_saved_label")
        sharedDefaults?.set(isSavingTime, forKey: "oruv_insights_is_saving_time")
        sharedDefaults?.set(totalMins, forKey: "oruv_insights_today_minutes")
        sharedDefaults?.set(effectiveYesterdayMinutes, forKey: "oruv_insights_yesterday_minutes")
        sharedDefaults?.set(absDiffMinutes, forKey: "oruv_insights_diff_minutes")

        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            let statsURL = containerURL.appendingPathComponent("screen_time_stats.json")
            let statsDict: [String: Any] = [
                "totalMinutes": totalMins,
                "yesterdayTotalMinutes": effectiveYesterdayMinutes,
                "timeSavedText": timeSavedText,
                "timeSavedLabel": timeSavedLabel,
                "isSavingTime": isSavingTime,
                "diffMinutes": absDiffMinutes,
                "insightsTimeSavedText": timeSavedText,
                "insightsTimeSavedLabel": timeSavedLabel,
                "insightsIsSavingTime": isSavingTime,
                "insightsTodayMinutes": totalMins,
                "insightsYesterdayMinutes": effectiveYesterdayMinutes
            ]
            if let json = try? JSONSerialization.data(withJSONObject: statsDict, options: []) {
                let coordinator = NSFileCoordinator(filePresenter: nil)
                coordinator.coordinate(writingItemAt: statsURL, options: .forReplacing, error: nil) { targetURL in
                    try? json.write(to: targetURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                    var mutableURL = targetURL
                    var values = URLResourceValues()
                    values.isExcludedFromBackup = true
                    try? mutableURL.setResourceValues(values)
                }
            }
        }

        let allTopApps = (distractingItems + otherItems)
            .sorted { $0.durationMinutes > $1.durationMinutes }
            .prefix(5)
        let insightsAppsPayload: [[String: Any]] = allTopApps.map { item in
            [
                "id": item.id,
                "name": item.displayName,
                "durationMinutes": item.durationMinutes,
                "isDistracting": item.isDistracting
            ]
        }
        sharedDefaults?.set(insightsAppsPayload, forKey: "oruv_daily_apps")
        sharedDefaults?.synchronize()

        return InsightsScreenTimeConfiguration(
            totalMinutes: totalMins,
            distractingMinutes: distractingMins,
            otherMinutes: otherMins,
            distractedPercentage: pctDistracted,
            timeSavedText: timeSavedText,
            timeSavedLabel: timeSavedLabel,
            isSavingTime: isSavingTime,
            pickupsPerHour: pickupsPerHour,
            distractingApps: distractingItems,
            otherApps: otherItems,
            weekTotalMinutes: weekTotalMins,
            weekDailyAverageMinutes: weekDailyAverageMins,
            weekDistractingMinutes: weekDistractingMins,
            weekOtherMinutes: weekOtherMins,
            weekDistractedPercentage: weekPctDistracted,
            weekTimeSavedText: weekTimeSavedText,
            weekTimeSavedLabel: weekTimeSavedLabel,
            weekIsSavingTime: weekIsSavingTime,
            weekHasLastWeekData: weekHasLastWeekData,
            weekLastWeekText: weekLastWeekText,
            weekLastWeekLabel: weekLastWeekLabel,
            weekIsUnderLastWeek: weekIsUnderLastWeek,
            weekDays: weekDays,
            weekDistractingApps: weekDistractingItems,
            weekOtherApps: weekOtherItems
        )
    }
}

nonisolated struct AnchorTimeSavedReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .anchorTimeSaved
    let content: (AnchorTimeSavedConfiguration) -> AnchorTimeSavedView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> AnchorTimeSavedConfiguration {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        var todayTotalSeconds: TimeInterval = 0
        var yesterdayTotalSeconds: TimeInterval = 0
        var appMap: [ApplicationToken: TimeInterval] = [:]

        for await activityData in data {
            for await segment in activityData.activitySegments {
                let isToday = segment.dateInterval.end > startOfToday
                if isToday {
                    todayTotalSeconds += segment.totalActivityDuration
                    for await categoryActivity in segment.categories {
                        for await appActivity in categoryActivity.applications {
                            let duration = appActivity.totalActivityDuration
                            guard duration >= 60, let token = appActivity.application.token else { continue }
                            let existing = appMap[token] ?? 0
                            appMap[token] = existing + duration
                        }
                    }
                } else {
                    yesterdayTotalSeconds += segment.totalActivityDuration
                }
            }
        }

        let appMins = appMap.values.reduce(0) { $0 + max(1, Int($1 / 60)) }
        let rawTodayMins = max(0, Int(todayTotalSeconds / 60))
        let todayMins = max(rawTodayMins, appMins)
        let yesterdayMins = max(0, Int(yesterdayTotalSeconds / 60))

        var baselineDailyMinutes = 300
        let appGroupId = "group.app.iftekarhossain.oruv"
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            let fileURL = containerURL.appendingPathComponent("insights_metrics.json")
            if let jsonData = try? Data(contentsOf: fileURL),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if let base = json["baselineMinutes"] as? Int, base > 0 {
                    baselineDailyMinutes = base
                }
            }
        }

        let effectiveYesterdayMinutes = yesterdayMins > 0 ? yesterdayMins : baselineDailyMinutes
        let diffMinutes = effectiveYesterdayMinutes - todayMins
        let isSavingTime = diffMinutes >= 0
        let absDiffMinutes = abs(diffMinutes)
        let timeText = AppActivityItem.formatMinutes(absDiffMinutes)
        let label = isSavingTime ? "On Track to Save" : "Over Yest."

        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        sharedDefaults?.set(todayMins, forKey: "oruv_daily_total_minutes")
        sharedDefaults?.set(effectiveYesterdayMinutes, forKey: "oruv_yesterday_total_minutes")
        sharedDefaults?.set(timeText, forKey: "oruv_time_saved_text")
        sharedDefaults?.set(label, forKey: "oruv_time_saved_label")
        sharedDefaults?.set(isSavingTime, forKey: "oruv_is_saving_time")
        sharedDefaults?.set(absDiffMinutes, forKey: "oruv_diff_minutes")

        return AnchorTimeSavedConfiguration(
            timeText: timeText,
            label: label,
            isSavingTime: isSavingTime
        )
    }
}
