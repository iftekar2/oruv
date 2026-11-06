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
        return DailyScreenTimeConfiguration(
            totalMinutes: totalMinutes,
            apps: sortedItems
        )
    }
}
