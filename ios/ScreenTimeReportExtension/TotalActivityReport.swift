import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

@available(iOS 16.0, *)
extension DeviceActivityReport.Context {
  static let dailyScreenTime = Self("DailyScreenTime")
}

@available(iOS 16.0, *)
struct AppActivityItem: Identifiable {
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

@available(iOS 16.0, *)
struct DailyScreenTimeConfiguration {
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

@available(iOS 16.0, *)
struct TotalActivityReport: DeviceActivityReportScene {
  let context: DeviceActivityReport.Context = .dailyScreenTime
  let content: (DailyScreenTimeConfiguration) -> DailyScreenTimeReportView

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
      .prefix(6)
      .map { $0 }

    let totalMinutes = max(0, Int(totalSeconds / 60))
    return DailyScreenTimeConfiguration(
      totalMinutes: totalMinutes,
      apps: sortedItems
    )
  }
}

@available(iOS 16.0, *)
struct DailyScreenTimeReportView: View {
  let configuration: DailyScreenTimeConfiguration

  private let primaryText = Color(red: 0.106, green: 0.106, blue: 0.114)
  private let mutedText = Color(red: 0.431, green: 0.416, blue: 0.431)
  private let coralPink = Color(red: 0.949, green: 0.408, blue: 0.475)
  private let trackColor = Color(red: 0.953, green: 0.925, blue: 0.922)

  var body: some View {
    let maxMins = max(1, configuration.apps.map(\.durationMinutes).max() ?? 1)

    VStack(alignment: .leading, spacing: 0) {
      Text(configuration.formattedTotalDuration)
        .font(.system(size: 27, weight: .bold, design: .serif))
        .foregroundColor(primaryText)

      Text("Today")
        .font(.system(size: 12.5, weight: .regular))
        .foregroundColor(mutedText)
        .padding(.top, 3)

      Divider()
        .background(Color(red: 0.949, green: 0.933, blue: 0.918))
        .padding(.vertical, 14)

      ForEach(configuration.apps) { item in
        let ratio = min(1.0, max(0.08, Double(item.durationMinutes) / Double(maxMins)))
        HStack(spacing: 12) {
          // Real App Icon from iOS Screen Time via Label(token)
          Label(item.token)
            .labelStyle(.iconOnly)
            .frame(width: 34, height: 34)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8.5, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 8.5, style: .continuous)
                .stroke(Color(red: 0.925, green: 0.910, blue: 0.894), lineWidth: 0.8)
            )

          VStack(alignment: .leading, spacing: 7) {
            HStack {
              Label(item.token)
                .labelStyle(.titleOnly)
                .font(.system(size: 13.5, weight: .semibold, design: .serif))
                .foregroundColor(primaryText)
                .lineLimit(1)

              Spacer()

              Text(item.formattedDuration)
                .font(.system(size: 12.5, weight: .semibold, design: .serif))
                .foregroundColor(primaryText)
            }

            GeometryReader { geo in
              ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                  .fill(trackColor)
                  .frame(height: 4.5)

                RoundedRectangle(cornerRadius: 4)
                  .fill(coralPink)
                  .frame(width: geo.size.width * ratio, height: 4.5)
              }
            }
            .frame(height: 4.5)
          }
        }
        .padding(.vertical, 9)
      }
    }
    .background(Color.white)
  }
}
