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
        if let image = UIImage(named: "AppLogo", in: bundle, compatibleWith: nil) {
            return image
        }
        if let path = bundle.path(forResource: "AppLogo", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        return UIImage(systemName: "shield.fill")
    }

    private func createShieldConfiguration(for entityName: String) -> ShieldConfiguration {
        let protectedToday = sharedDefaults?.string(forKey: "oruv_protected_today") ?? "4h 12m"
        let sessionRemaining = sharedDefaults?.string(forKey: "oruv_session_remaining")
        let totalMinutes = sharedDefaults?.integer(forKey: "oruv_daily_total_minutes") ?? 0
        let screenTimeStr = formatMinutes(totalMinutes > 0 ? totalMinutes : 105)

        var subtitleParts: [String] = []
        subtitleParts.append("\(entityName) is blocked by Oruv to protect your focus.")
        subtitleParts.append("")

        if let sessionRemaining = sessionRemaining, !sessionRemaining.isEmpty {
            subtitleParts.append("⏱ \(sessionRemaining) Session Remaining")
        }
        subtitleParts.append("🛡 \(protectedToday) Protected Today")
        subtitleParts.append("📱 \(screenTimeStr) Screen Time Today")

        let subtitleText = subtitleParts.joined(separator: "\n")

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0),
            icon: appLogoImage,
            title: ShieldConfiguration.Label(
                text: "Oruv Focus Shield",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: UIColor(white: 0.86, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Got It",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.114, green: 0.435, blue: 0.345, alpha: 1.0)
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

