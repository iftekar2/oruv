import DeviceActivity
import ExtensionKit
import FamilyControls
@preconcurrency import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let dailyScreenTime = Self("DailyScreenTime")
    static let totalActivity = Self("Total Activity")
}

struct AppActivityItem: Identifiable, Sendable {
    let id: String
    let token: ApplicationToken
    let displayName: String
    let durationMinutes: Int

    var formattedDuration: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
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
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
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
        let sharedDefaults = UserDefaults(suiteName: "group.app.iftekarhossain.oruv")
        sharedDefaults?.set(totalMinutes, forKey: "oruv_daily_total_minutes")

        // Read selected distracting apps from UserDefaults
        var distractingTokens: Set<ApplicationToken> = []
        if let selData = sharedDefaults?.data(forKey: "oruv_family_activity_selection"),
           let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: selData) {
            distractingTokens = selection.applicationTokens
        }

        var appArray: [[String: Any]] = []
        for (token, info) in appDurations {
            let durationMins = max(1, Int(info.seconds / 60))
            let isDistracting = distractingTokens.contains(token)
            appArray.append([
                "name": info.name,
                "durationMinutes": durationMins,
                "isDistracting": isDistracting
            ])
        }
        appArray.sort { ($0["durationMinutes"] as? Int ?? 0) > ($1["durationMinutes"] as? Int ?? 0) }
        sharedDefaults?.set(appArray, forKey: "oruv_daily_apps")

        // Persist known app names to the shared App Group for blocked attempts resolution
        var tokenNameDict: [String: String] = (sharedDefaults?.dictionary(forKey: "oruv_blocked_token_names") as? [String: String]) ?? [:]
        for (token, info) in appDurations {
            if !info.name.isEmpty, info.name != "App",
               let encoded = try? PropertyListEncoder().encode(token) {
                let tokenKey = "app:" + encoded.base64EncodedString()
                tokenNameDict[tokenKey] = info.name
            }
        }
        if !tokenNameDict.isEmpty {
            sharedDefaults?.set(tokenNameDict, forKey: "oruv_blocked_token_names")
        }

        return DailyScreenTimeConfiguration(
            totalMinutes: totalMinutes,
            apps: sortedItems
        )
    }
}
