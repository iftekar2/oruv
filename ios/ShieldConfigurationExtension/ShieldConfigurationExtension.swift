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
            "h": "𝐡", "m": "𝐦", "X": "𝐗", "x": "𝐱", " ": "\u{00A0}"
        ]
        return text.map { map[$0] ?? String($0) }.joined()
    }

    /// Persists the known app name and token mapping to the shared App Group container
    /// so ShieldActionExtension and the main Flutter app can immediately resolve the app name.
    private func recordKnownAppName(_ name: String, for tokenKey: String?) {
        guard !name.isEmpty, name != "This app", name != "This website" else { return }

        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        )
        let namesURL = containerURL?.appendingPathComponent("app_names.json")
        let fileURL = containerURL?.appendingPathComponent("blocked_attempts.json")

        // 1. Update app_names.json
        var namesDict: [String: String] = [:]
        if let namesURL = namesURL,
           let data = try? Data(contentsOf: namesURL),
           let saved = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            namesDict = saved
        }
        if let key = tokenKey {
            namesDict[key] = name
        }
        namesDict["last"] = name
        if let namesURL = namesURL,
           let data = try? JSONSerialization.data(withJSONObject: namesDict, options: []) {
            try? data.write(to: namesURL, options: .atomic)
        }

        // 2. Update blocked_attempts.json if it exists
        if let fileURL = fileURL,
           let data = try? Data(contentsOf: fileURL),
           var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            var tokenNames = (json["tokenNames"] as? [String: String]) ?? [:]
            if let key = tokenKey {
                tokenNames[key] = name
            }
            json["tokenNames"] = tokenNames
            let currentTopName = (json["mostBlockedAppName"] as? String) ?? ""
            if currentTopName.isEmpty {
                json["mostBlockedAppName"] = name
            }
            if let updatedData = try? JSONSerialization.data(withJSONObject: json, options: []) {
                try? updatedData.write(to: fileURL, options: .atomic)
            }
        }

        // 3. Update UserDefaults suite
        sharedDefaults?.set(name, forKey: "oruv_last_shielded_app_name")
        var userDefaultsNames = (sharedDefaults?.dictionary(forKey: "oruv_blocked_token_names") as? [String: String]) ?? [:]
        if let key = tokenKey {
            userDefaultsNames[key] = name
        }
        sharedDefaults?.set(userDefaultsNames, forKey: "oruv_blocked_token_names")
        if (sharedDefaults?.string(forKey: "oruv_most_blocked_app_name") ?? "").isEmpty {
            sharedDefaults?.set(name, forKey: "oruv_most_blocked_app_name")
        }
        sharedDefaults?.synchronize()
    }

    /// Resolves the localized display name for a stored token key inside ShieldConfigurationExtension.
    private func resolveDisplayName(
        for tokenKey: String,
        savedNames: [String: String],
        fallback: String
    ) -> String {
        if let saved = savedNames[tokenKey], !saved.isEmpty {
            return saved
        }
        if tokenKey.hasPrefix("app:") {
            let base64 = String(tokenKey.dropFirst(4))
            if let data = Data(base64Encoded: base64),
               let token = try? PropertyListDecoder().decode(ApplicationToken.self, from: data),
               let name = Application(token: token).localizedDisplayName,
               !name.isEmpty {
                return name
            }
        } else if tokenKey.hasPrefix("cat:") {
            let base64 = String(tokenKey.dropFirst(4))
            if let data = Data(base64Encoded: base64),
               let token = try? PropertyListDecoder().decode(ActivityCategoryToken.self, from: data),
               let name = ActivityCategory(token: token).localizedDisplayName,
               !name.isEmpty {
                return name
            }
        } else if tokenKey.hasPrefix("web:") {
            let base64 = String(tokenKey.dropFirst(4))
            if let data = Data(base64Encoded: base64),
               let token = try? PropertyListDecoder().decode(WebDomainToken.self, from: data),
               let domain = WebDomain(token: token).domain,
               !domain.isEmpty {
                return domain
            }
        } else if tokenKey.hasPrefix("name:") {
            return String(tokenKey.dropFirst(5))
        }
        return fallback
    }

    /// Reads confirmed blocked attempts written by `ShieldActionExtension` in the shared App Group,
    /// includes +1 for the current active shield presentation, and resolves the most-blocked app.
    private func resolveMostBlockedAttempt(
        for entityName: String,
        tokenKey: String?
    ) -> (appName: String, count: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())

        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        )
        let fileURL = containerURL?.appendingPathComponent("blocked_attempts.json")

        var tokenCounts: [String: Int] = [:]
        var tokenNames: [String: String] = [:]

        if let fileURL = fileURL,
           let data = try? Data(contentsOf: fileURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           (json["date"] as? String) == todayStr {
            tokenCounts = (json["tokenCounts"] as? [String: Int]) ?? [:]
            tokenNames = (json["tokenNames"] as? [String: String]) ?? [:]
        } else if sharedDefaults?.string(forKey: "oruv_blocked_attempts_date") == todayStr {
            tokenCounts = (sharedDefaults?.dictionary(forKey: "oruv_blocked_token_counts") as? [String: Int]) ?? [:]
            tokenNames = (sharedDefaults?.dictionary(forKey: "oruv_blocked_token_names") as? [String: String]) ?? [:]
        }

        let currentKey = tokenKey ?? "name:\(entityName)"
        // Add +1 for the shield presentation currently on screen (which ShieldActionExtension
        // will persist when the user taps "Got It").
        tokenCounts[currentKey, default: 0] += 1
        tokenNames[currentKey] = entityName

        let mostBlocked = tokenCounts.max(by: { $0.value < $1.value })
        let topKey = mostBlocked?.key ?? currentKey
        let topCount = mostBlocked?.value ?? 1
        let topAppName = (topKey == currentKey)
            ? entityName
            : resolveDisplayName(for: topKey, savedNames: tokenNames, fallback: entityName)

        return (topAppName, topCount)
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
            lines.append(boldSerifMetric("\(mostBlockedCount)X"))
            lines.append("\(mostBlockedAppName) Blocked")
        }

        return lines
    }

    private func createShieldConfiguration(
        for entityName: String,
        tokenKey: String?
    ) -> ShieldConfiguration {
        let attempt = resolveMostBlockedAttempt(for: entityName, tokenKey: tokenKey)

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

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let name = application.localizedDisplayName ?? "This app"
        let tokenKey = application.token
            .flatMap { try? PropertyListEncoder().encode($0) }
            .map { "app:" + $0.base64EncodedString() }
        recordKnownAppName(name, for: tokenKey)
        return createShieldConfiguration(for: name, tokenKey: tokenKey)
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        let name = application.localizedDisplayName ?? "This app"
        let tokenKey = application.token
            .flatMap { try? PropertyListEncoder().encode($0) }
            .map { "app:" + $0.base64EncodedString() }
        recordKnownAppName(name, for: tokenKey)
        return createShieldConfiguration(for: name, tokenKey: tokenKey)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let domain = webDomain.domain ?? "This website"
        let tokenKey = webDomain.token
            .flatMap { try? PropertyListEncoder().encode($0) }
            .map { "web:" + $0.base64EncodedString() }
        recordKnownAppName(domain, for: tokenKey)
        return createShieldConfiguration(for: domain, tokenKey: tokenKey)
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        let domain = webDomain.domain ?? "This website"
        let tokenKey = webDomain.token
            .flatMap { try? PropertyListEncoder().encode($0) }
            .map { "web:" + $0.base64EncodedString() }
        recordKnownAppName(domain, for: tokenKey)
        return createShieldConfiguration(for: domain, tokenKey: tokenKey)
    }
}
