import DeviceActivity
import ExtensionKit
import FamilyControls
@preconcurrency import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let dailyScreenTime = Self("DailyScreenTime")
    static let insightsScreenTime = Self("InsightsScreenTime")
    static let totalActivity = Self("Total Activity")
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

struct InsightsScreenTimeConfiguration: Sendable {
    let totalMinutes: Int
    let distractingMinutes: Int
    let otherMinutes: Int
    let distractedPercentage: Int
    let timeSavedText: String
    let pickupsPerHour: Int
    let distractingApps: [InsightsAppActivityItem]
    let otherApps: [InsightsAppActivityItem]

    var formattedTotalDuration: String {
        AppActivityItem.formatMinutes(totalMinutes)
    }

    var formattedDistractingDuration: String {
        AppActivityItem.formatMinutes(distractingMinutes)
    }

    var formattedOtherDuration: String {
        AppActivityItem.formatMinutes(otherMinutes)
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
        var totalSeconds: TimeInterval = 0
        var appDurations: [ApplicationToken: (name: String, seconds: TimeInterval)] = [:]

        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalSeconds += segment.totalActivityDuration
                for await categoryActivity in segment.categories {
                    for await appActivity in categoryActivity.applications {
                        let duration = appActivity.totalActivityDuration
                        guard duration >= 60, let token = appActivity.application.token else { continue }
                        let name = appActivity.application.localizedDisplayName ?? "App"
                        let existing = appDurations[token]?.seconds ?? 0
                        appDurations[token] = (name: name, seconds: existing + duration)
                    }
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

        let totalMinutes = max(0, Int(totalSeconds / 60))

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

        var totalSeconds: TimeInterval = 0
        var totalPickups: Int = 0
        var earliestPickup: Date? = nil

        struct RawAppAccumulator {
            var name: String
            var bundleId: String
            var categoryName: String
            var categoryToken: ActivityCategoryToken?
            var seconds: TimeInterval
            var pickups: Int
        }

        var appMap: [ApplicationToken: RawAppAccumulator] = [:]

        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalSeconds += segment.totalActivityDuration
                totalPickups += segment.totalPickupsWithoutApplicationActivity
                if let fp = segment.firstPickup {
                    if earliestPickup == nil || fp < earliestPickup! {
                        earliestPickup = fp
                    }
                }

                for await categoryActivity in segment.categories {
                    let catName = categoryActivity.category.localizedDisplayName ?? ""
                    let catToken = categoryActivity.category.token

                    for await appActivity in categoryActivity.applications {
                        let duration = appActivity.totalActivityDuration
                        let pickups = appActivity.numberOfPickups
                        totalPickups += pickups

                        guard duration >= 60, let token = appActivity.application.token else { continue }
                        let name = appActivity.application.localizedDisplayName ?? "App"
                        let bundleId = appActivity.application.bundleIdentifier ?? ""

                        if var existing = appMap[token] {
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
                            appMap[token] = existing
                        } else {
                            appMap[token] = RawAppAccumulator(
                                name: name,
                                bundleId: bundleId,
                                categoryName: catName,
                                categoryToken: catToken,
                                seconds: duration,
                                pickups: pickups
                            )
                        }
                    }
                }
            }
        }

        var distractingItems: [InsightsAppActivityItem] = []
        var otherItems: [InsightsAppActivityItem] = []

        for (token, info) in appMap {
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
                distractingItems.append(item)
            } else {
                otherItems.append(item)
            }
        }

        distractingItems.sort { $0.durationMinutes > $1.durationMinutes }
        otherItems.sort { $0.durationMinutes > $1.durationMinutes }

        let distractingMins = distractingItems.reduce(0) { $0 + $1.durationMinutes }
        let otherMins = otherItems.reduce(0) { $0 + $1.durationMinutes }
        let rawTotalMins = max(0, Int(totalSeconds / 60))
        let totalMins = max(rawTotalMins, distractingMins + otherMins)

        // 1. % DISTRACTED
        let pctDistracted: Int
        if totalMins > 0 {
            pctDistracted = min(100, max(0, Int(round(Double(distractingMins) / Double(totalMins) * 100.0))))
        } else {
            pctDistracted = 0
        }

        // 2. PICKUPS / HR
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let sevenAM = startOfDay.addingTimeInterval(7 * 3600)
        let referenceStart: Date
        if let fp = earliestPickup {
            referenceStart = fp
        } else if now > sevenAM {
            referenceStart = sevenAM
        } else {
            referenceStart = startOfDay
        }
        let elapsedHours = max(1.0, now.timeIntervalSince(referenceStart) / 3600.0)
        let pickupsPerHour: Int
        if totalPickups > 0 {
            pickupsPerHour = max(1, Int(round(Double(totalPickups) / elapsedHours)))
        } else if totalMins > 0 {
            pickupsPerHour = max(1, Int(round(Double(appMap.count) / elapsedHours)))
        } else {
            pickupsPerHour = 0
        }

        // 3. TIME SAVED (Dynamic calculation combining elapsed waking day baseline vs actual distracting usage & active shields)
        var baselineDailyMinutes = 300 // 5h default daily distraction/screen baseline
        var elapsedShieldSavedMinutes = 0

        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            let fileURL = containerURL.appendingPathComponent("insights_metrics.json")
            if let jsonData = try? Data(contentsOf: fileURL),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if let base = json["baselineMinutes"] as? Int, base > 0 {
                    baselineDailyMinutes = base
                }
                if let shieldSaved = json["elapsedSavedMinutes"] as? Int, shieldSaved >= 0 {
                    elapsedShieldSavedMinutes = shieldSaved
                }
            }
        }

        let minutesSinceMidnight = Int(now.timeIntervalSince(startOfDay) / 60.0)
        let wakingElapsedMins = max(30, min(960, minutesSinceMidnight - 420)) // 7:00 AM to 11:00 PM (960 mins)
        let expectedDistractingSoFar = Int(round(Double(baselineDailyMinutes) * (Double(wakingElapsedMins) / 960.0) * 0.65))
        let savedVsBaseline = max(0, expectedDistractingSoFar - distractingMins)
        let effectiveSavedMinutes = max(savedVsBaseline, elapsedShieldSavedMinutes)
        let timeSavedText = AppActivityItem.formatMinutes(effectiveSavedMinutes)

        return InsightsScreenTimeConfiguration(
            totalMinutes: totalMins,
            distractingMinutes: distractingMins,
            otherMinutes: otherMins,
            distractedPercentage: pctDistracted,
            timeSavedText: timeSavedText,
            pickupsPerHour: pickupsPerHour,
            distractingApps: distractingItems,
            otherApps: otherItems
        )
    }
}
