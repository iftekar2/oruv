import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    private let appGroupId = "group.app.iftekarhossain.oruv"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    private var appLogoImage: UIImage? {
        let bundle = Bundle(for: ShieldConfigurationExtension.self)
        let rawImage: UIImage? = {
            if let image = UIImage(named: "AppLogo", in: bundle, compatibleWith: nil) {
                return image
            }
            if let path = bundle.path(forResource: "AppLogo", ofType: "png"),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
            return nil
        }()

        guard let source = rawImage else {
            return UIImage(systemName: "shield.fill")
        }

        // Render with smooth rounded corners so the icon doesn't appear as a sharp square
        let size = source.size
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let radius = min(size.width, size.height) * 0.22
            UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
            source.draw(in: rect)
        }
    }

    /// Converts digits and h/m units into Unicode Mathematical Bold Serif glyphs (e.g. 2h 15m -> 𝟐𝐡 𝟏𝟓𝐦)
    /// so the metric numbers stand out boldly above each label inside ShieldConfiguration.Label.
    private func boldSerifMetric(_ text: String) -> String {
        let map: [Character: String] = [
            "0": "𝟎", "1": "𝟏", "2": "𝟐", "3": "𝟑", "4": "𝟒",
            "5": "𝟓", "6": "𝟔", "7": "𝟕", "8": "𝟖", "9": "𝟗",
            "h": "𝐡", "m": "𝐦", " ": "\u{00A0}"
        ]
        return text.map { map[$0] ?? String($0) }.joined()
    }

    /// Records a genuine blocked open attempt with debounce to prevent duplicate layout / background snapshot calls.
    private func recordBlockedAttempt(for entityName: String) -> (appName: String, count: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())

        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
        let fileURL = containerURL?.appendingPathComponent("blocked_attempts.json")

        // 1. Read existing attempts from shared JSON file or UserDefaults
        var attempts: [String: Int] = [:]
        var lastOpenTimestamps: [String: Double] = (sharedDefaults?.dictionary(forKey: "oruv_last_open_timestamps") as? [String: Double]) ?? [:]

        if let fileURL = fileURL,
           let data = try? Data(contentsOf: fileURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           (json["date"] as? String) == todayStr,
           let fileAttempts = json["attempts"] as? [String: Int] {
            attempts = fileAttempts
        } else {
            let savedDate = sharedDefaults?.string(forKey: "oruv_blocked_attempts_date")
            if savedDate == todayStr {
                attempts = (sharedDefaults?.dictionary(forKey: "oruv_blocked_attempts_today") as? [String: Int]) ?? [:]
            }
        }

        // 2. Debounce: Only increment if at least 3.5 seconds have passed since this app was last shielded.
        // This eliminates duplicate system layout calls and background snapshotting.
        let now = Date().timeIntervalSince1970
        let lastOpen = lastOpenTimestamps[entityName] ?? 0
        if (now - lastOpen) >= 3.5 {
            attempts[entityName, default: 0] += 1
            lastOpenTimestamps[entityName] = now
            sharedDefaults?.set(lastOpenTimestamps, forKey: "oruv_last_open_timestamps")
        }

        let mostBlocked = attempts.max(by: { $0.value < $1.value })
        let topApp = mostBlocked?.key ?? entityName
        let topCount = mostBlocked?.value ?? attempts[entityName] ?? 1
        let total = attempts.values.reduce(0, +)

        // 3. Save to shared file in App Group (guaranteed immediate cross-process visibility)
        if let fileURL = fileURL {
            let jsonPayload: [String: Any] = [
                "date": todayStr,
                "attempts": attempts,
                "mostBlockedAppName": topApp,
                "mostBlockedCount": topCount,
                "total": total
            ]
            if let data = try? JSONSerialization.data(withJSONObject: jsonPayload, options: []) {
                try? data.write(to: fileURL, options: .atomic)
            }
        }

        // 4. Save to UserDefaults as well with explicit synchronize
        sharedDefaults?.set(todayStr, forKey: "oruv_blocked_attempts_date")
        sharedDefaults?.set(attempts, forKey: "oruv_blocked_attempts_today")
        sharedDefaults?.set(topApp, forKey: "oruv_most_blocked_app_name")
        sharedDefaults?.set(topCount, forKey: "oruv_most_blocked_app_count")
        sharedDefaults?.set(total, forKey: "oruv_total_blocked_today")
        sharedDefaults?.synchronize()

        return (topApp, topCount)
    }

    /// Builds a vertical column layout for the metrics without any divider bars.
    private func buildMetricsSection(
        sessionRemaining: String?,
        projectedTime: String,
        projectedLabel: String,
        isSavingTime: Bool,
        mostBlockedAppName: String,
        mostBlockedCount: Int
    ) -> [String] {
        var lines: [String] = []

        let session = (sessionRemaining?.isEmpty == false) ? sessionRemaining : "2h 15m"
        if let session = session {
            lines.append(boldSerifMetric(session))
            lines.append("Session Remaining")
            lines.append("")
        }

        let arrow = isSavingTime ? "↓\u{00A0}" : "↑\u{00A0}"
        lines.append(arrow + boldSerifMetric(projectedTime))
        lines.append(projectedLabel)

        if mostBlockedCount > 0 {
            lines.append("")
            lines.append(boldSerifMetric("\(mostBlockedCount)x"))
            lines.append("\(mostBlockedAppName) Blocked Today")
        }

        return lines
    }

    private func createShieldConfiguration(for entityName: String) -> ShieldConfiguration {
        // Record blocked attempt for this app and get the most frequently blocked app
        let attempt = recordBlockedAttempt(for: entityName)

        // Fetch saved metrics from App Group UserDefaults
        let rawSession = sharedDefaults?.string(forKey: "oruv_session_remaining")?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sessionRemaining = (rawSession?.isEmpty == false) ? rawSession : "2h 15m"
        
        let projectedTime = sharedDefaults?.string(forKey: "oruv_projected_time")
            ?? sharedDefaults?.string(forKey: "oruv_protected_today")
            ?? "1h 05m"
        let isSavingTime = sharedDefaults?.object(forKey: "oruv_is_saving_time") as? Bool ?? true
        let defaultLabel = isSavingTime ? "On Track to Save vs Yesterday" : "Projected Over Yesterday"
        let projectedLabel = sharedDefaults?.string(forKey: "oruv_projected_label") ?? defaultLabel

        var subtitleLines: [String] = [
            "\(entityName) is blocked by Oruv to protect your focus.",
            ""
        ]
        subtitleLines.append(
            contentsOf: buildMetricsSection(
                sessionRemaining: sessionRemaining,
                projectedTime: projectedTime,
                projectedLabel: projectedLabel,
                isSavingTime: isSavingTime,
                mostBlockedAppName: attempt.appName,
                mostBlockedCount: attempt.count
            )
        )

        let subtitleText = subtitleLines.joined(separator: "\n")

        return ShieldConfiguration(
            // Force a light blur style so iOS Dark Mode doesn't turn the shield dark gray behind dark text
            backgroundBlurStyle: .systemUltraThinMaterialLight,
            backgroundColor: .white,
            icon: appLogoImage,
            title: ShieldConfiguration.Label(
                text: "Oruv Focus Shield",
                color: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: UIColor(red: 0.24, green: 0.22, blue: 0.22, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Got It",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.114, green: 0.435, blue: 0.345, alpha: 1.0) // Oruv Emerald #1D6F58
        )
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let name = application.localizedDisplayName ?? "This app"
        return createShieldConfiguration(for: name)
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        let name = application.localizedDisplayName ?? "This app"
        return createShieldConfiguration(for: name)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let domain = webDomain.domain ?? "This website"
        return createShieldConfiguration(for: domain)
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        let domain = webDomain.domain ?? "This website"
        return createShieldConfiguration(for: domain)
    }
}