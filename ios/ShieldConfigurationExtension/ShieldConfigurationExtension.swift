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

    /// Builds a vertical column layout for the metrics without any divider bars.
    private func buildMetricsSection(
        sessionRemaining: String?,
        protectedToday: String
    ) -> [String] {
        var lines: [String] = []

        let session = (sessionRemaining?.isEmpty == false) ? sessionRemaining : "2h 15m"
        if let session = session {
            lines.append(boldSerifMetric(session))
            lines.append("Session Remaining")
            lines.append("")
        }

        lines.append(boldSerifMetric(protectedToday))
        lines.append("Protected Today")

        return lines
    }

    private func createShieldConfiguration(for entityName: String) -> ShieldConfiguration {
        // Fetch saved metrics from App Group UserDefaults
        let rawSession = sharedDefaults?.string(forKey: "oruv_session_remaining")?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sessionRemaining = (rawSession?.isEmpty == false) ? rawSession : "2h 15m"
        let protectedToday = sharedDefaults?.string(forKey: "oruv_protected_today") ?? "4h 12m"

        var subtitleLines: [String] = [
            "\(entityName) is blocked by Oruv to protect your focus.",
            ""
        ]
        subtitleLines.append(
            contentsOf: buildMetricsSection(
                sessionRemaining: sessionRemaining,
                protectedToday: protectedToday
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