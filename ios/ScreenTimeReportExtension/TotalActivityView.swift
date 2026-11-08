import DeviceActivity
import FamilyControls
@preconcurrency import ManagedSettings
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
                .padding(.top, 2)

            Divider()
                .background(Color(red: 0.949, green: 0.933, blue: 0.918))
                .padding(.vertical, 10)

            if configuration.apps.isEmpty {
                Text("No app activity recorded yet today.")
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(mutedText)
                    .padding(.vertical, 6)
            } else {
                ForEach(configuration.apps) { item in
                    let ratio = min(1.0, max(0.08, Double(item.durationMinutes) / Double(maxMins)))

                    HStack(alignment: .center, spacing: 14) {
                        // App Icon (vertically centered)
                        Label(item.token)
                            .labelStyle(.iconOnly)
                            .frame(width: 34, height: 34)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8.5, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8.5, style: .continuous)
                                    .stroke(Color(red: 0.925, green: 0.910, blue: 0.894), lineWidth: 0.8)
                            )

                        // Timer Bar (centered vertically with the icon)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(trackColor)
                                    .frame(height: 4.5)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(coralPink)
                                    .frame(width: max(4.5, geo.size.width * ratio), height: 4.5)
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                        }
                        .frame(height: 4.5)

                        // Duration Text (vertically centered with the icon)
                        Text(item.formattedDuration)
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundColor(primaryText)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                    .frame(height: 38)
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.white)
        .allowsHitTesting(false)
    }
}

struct InsightsActivityView: View {
    let configuration: InsightsScreenTimeConfiguration
    @State private var selectedGranularity: String = "D"

    // Editorial Cream & Emerald Palette
    private let primaryText = Color(red: 0.106, green: 0.106, blue: 0.114) // #1B1B1D
    private let mutedText = Color(red: 0.431, green: 0.416, blue: 0.431)   // #6E6A6E
    private let emeraldGreen = Color(red: 0.086, green: 0.396, blue: 0.306) // #16654E
    private let redBarColor = Color(red: 0.898, green: 0.224, blue: 0.208)  // #E53935
    private let mintBarColor = Color(red: 0.455, green: 0.776, blue: 0.616) // #74C69D
    private let greyBarColor = Color(red: 0.494, green: 0.467, blue: 0.467) // #7E7777
    private let trackColor = Color(red: 0.953, green: 0.922, blue: 0.914)   // #F3EBE9
    private let dividerColor = Color(red: 0.957, green: 0.937, blue: 0.918) // #F4EFEA

    var body: some View {
        let allMax = max(
            configuration.distractingApps.map(\.durationMinutes).max() ?? 1,
            configuration.otherApps.map(\.durationMinutes).max() ?? 1
        )
        let maxAppMins = max(1, allMax)

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // ─── 1. TOP HERO: Screen Time + Granularity Switcher ────────
                heroHeader
                    .padding(.bottom, 22)

                // ─── 2. 3-COLUMN METRICS SUMMARY CARD ────────────────────────
                metricsSummaryCard
                    .padding(.bottom, 26)

                // ─── 3. DISTRACTING APPS SECTION ─────────────────────────────
                sectionHeader(
                    title: "Distracting Apps",
                    durationText: configuration.formattedDistractingDuration
                )
                .padding(.bottom, 10)

                appSectionList(
                    apps: configuration.distractingApps,
                    maxAppMinutes: maxAppMins,
                    isOtherSection: false,
                    emptyMessage: "No distracting app activity recorded today."
                )
                .padding(.bottom, 36)

                // ─── 4. OTHER APPS SECTION ───────────────────────────────────
                sectionHeader(
                    title: "Other Apps",
                    durationText: configuration.formattedOtherDuration
                )
                .padding(.bottom, 10)

                appSectionList(
                    apps: configuration.otherApps,
                    maxAppMinutes: maxAppMins,
                    isOtherSection: true,
                    emptyMessage: "No other app activity recorded today."
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
    }

    // ─── HERO HEADER ─────────────────────────────────────────────────────────

    private var heroHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Screen Time")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(mutedText)

                Text(configuration.formattedTotalDuration)
                    .font(.system(size: 44, weight: .heavy, design: .serif))
                    .foregroundColor(primaryText)
            }

            Spacer()

            granularityPill
                .padding(.top, 4)
        }
    }

    private var granularityPill: some View {
        HStack(spacing: 0) {
            ForEach(["D", "W", "M"], id: \.self) { granularity in
                let isSelected = selectedGranularity == granularity
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedGranularity = granularity
                    }
                } label: {
                    Text(granularity)
                        .font(.system(size: 14.5, weight: isSelected ? .bold : .medium, design: .serif))
                        .foregroundColor(isSelected ? .white : Color(red: 0.290, green: 0.290, blue: 0.290))
                        .frame(minWidth: 36, minHeight: 34)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(isSelected ? Color(red: 0.149, green: 0.137, blue: 0.149) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4.5)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.976, green: 0.965, blue: 0.957))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(red: 0.937, green: 0.914, blue: 0.898), lineWidth: 1.2)
        )
    }

    // ─── 3-COLUMN METRICS SUMMARY CARD ───────────────────────────────────────

    private var metricsSummaryCard: some View {
        HStack(spacing: 0) {
            metricColumn(
                value: "\(configuration.distractedPercentage)%",
                label: "Distracted",
                valueColor: primaryText
            )
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(red: 0.937, green: 0.910, blue: 0.898))
                .frame(width: 1, height: 28)

            metricColumn(
                value: configuration.timeSavedText,
                label: configuration.timeSavedLabel,
                valueColor: configuration.isSavingTime ? emeraldGreen : redBarColor
            )
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(red: 0.937, green: 0.910, blue: 0.898))
                .frame(width: 1, height: 28)

            metricColumn(
                value: "\(configuration.pickupsPerHour)",
                label: "Pickups/HR",
                valueColor: primaryText
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.992, green: 0.984, blue: 0.976))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.941, green: 0.918, blue: 0.902), lineWidth: 1.2)
        )
    }

    private func metricColumn(value: String, label: String, valueColor: Color) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .serif))
                .foregroundColor(valueColor)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.2)
                .foregroundColor(mutedText)
                .lineLimit(1)
        }
    }

    // ─── SECTION HEADER ──────────────────────────────────────────────────────

    private func sectionHeader(title: String, durationText: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(primaryText)

            Spacer()

            Text(durationText)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(primaryText)
        }
    }

    // ─── DYNAMIC APP LIST ────────────────────────────────────────────────────

    @ViewBuilder
    private func appSectionList(
        apps: [InsightsAppActivityItem],
        maxAppMinutes: Int,
        isOtherSection: Bool,
        emptyMessage: String
    ) -> some View {
        if apps.isEmpty {
            Text(emptyMessage)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .foregroundColor(mutedText)
                .padding(.vertical, 8)
                .padding(.horizontal, 2)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(apps.enumerated()), id: \.element.id) { index, item in
                    let ratio = min(1.0, max(0.06, Double(item.durationMinutes) / Double(maxAppMinutes)))
                    let barColor: Color = {
                        if !isOtherSection {
                            return redBarColor
                        }
                        if item.isOruv {
                            return emeraldGreen
                        } else if item.isBrowser {
                            return mintBarColor
                        } else {
                            return greyBarColor
                        }
                    }()

                    appRow(item: item, ratio: ratio, barColor: barColor)

                    if index < apps.count - 1 {
                        Divider()
                            .background(dividerColor)
                            .padding(.vertical, 11)
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    private func appRow(
        item: InsightsAppActivityItem,
        ratio: Double,
        barColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                // Real iOS App Icon rendered directly from ApplicationToken
                Label(item.token)
                    .labelStyle(.iconOnly)
                    .frame(width: 38, height: 38)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(red: 0.925, green: 0.910, blue: 0.894), lineWidth: 0.8)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    if !item.displayName.isEmpty && item.displayName != "App" {
                        Text(item.displayName)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(primaryText)
                            .lineLimit(1)
                    } else {
                        Label(item.token)
                            .labelStyle(.titleOnly)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(primaryText)
                            .lineLimit(1)
                    }

                    if item.isOruv {
                        Text("Deep Work")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(emeraldGreen)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.formattedDuration)
                    .font(.system(size: 13.5, weight: .bold, design: .serif))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .layoutPriority(1)
            }

            // Full-width horizontal progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(trackColor)
                        .frame(height: 7)

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(barColor)
                        .frame(width: max(7, geo.size.width * ratio), height: 7)
                }
            }
            .frame(height: 7)
        }
    }
}

struct AnchorTimeSavedView: View {
    let configuration: AnchorTimeSavedConfiguration

    private let accentGreen = Color(red: 0.114, green: 0.435, blue: 0.345) // #1D6F58
    private let coralRed = Color(red: 0.851, green: 0.282, blue: 0.255)    // #D94841

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: configuration.isSavingTime ? "arrowtriangle.down.fill" : "arrowtriangle.up.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(configuration.isSavingTime ? accentGreen : coralRed)

            Text(configuration.timeText)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(configuration.isSavingTime ? accentGreen : coralRed)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
