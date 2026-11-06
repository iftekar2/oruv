import DeviceActivity
import FamilyControls
import SwiftUI

struct TotalActivityView: View {
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

            if configuration.apps.isEmpty {
                Text("No app activity recorded yet today.")
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(mutedText)
                    .padding(.vertical, 8)
            } else {
                ForEach(configuration.apps) { item in
                    let ratio = min(1.0, max(0.08, Double(item.durationMinutes) / Double(maxMins)))
                    HStack(spacing: 12) {
                        // Real App Icon from iOS Screen Time
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
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }
}
