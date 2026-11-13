import Foundation
import ManagedSettings

/// Handles button taps ("Got It") on the Oruv Focus Shield.
/// Unlike `ShieldConfigurationExtension` (which runs inside Apple's read-only
/// `managed-settings-shield-configuration` sandbox), `ShieldActionExtension`
/// (`com.apple.ManagedSettings.shield-action-service`) has full write access
/// to the shared App Group container so the main Oruv app can read the exact
/// blocked attempt counts and `ApplicationToken` for the Home screen.
class ShieldActionExtension: ShieldActionDelegate {
    private let appGroupId = "group.app.iftekarhossain.oruv"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    private func resolveName(for tokenKey: String) -> String? {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        )

        // 1. Check app_names.json written by ShieldConfigurationExtension
        if let namesURL = containerURL?.appendingPathComponent("app_names.json"),
           let data = try? Data(contentsOf: namesURL),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            if let name = dict[tokenKey], !name.isEmpty {
                return name
            }
            if let last = dict["last"], !last.isEmpty {
                return last
            }
        }

        // 2. Check tokenNames in blocked_attempts.json
        if let fileURL = containerURL?.appendingPathComponent("blocked_attempts.json"),
           let data = try? Data(contentsOf: fileURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let tokenNames = json["tokenNames"] as? [String: String],
           let name = tokenNames[tokenKey], !name.isEmpty {
            return name
        }

        // 3. Check UserDefaults token dictionary
        if let tokenNames = sharedDefaults?.dictionary(forKey: "oruv_blocked_token_names") as? [String: String],
           let name = tokenNames[tokenKey], !name.isEmpty {
            return name
        }

        // 4. Check last shielded app name
        if let last = sharedDefaults?.string(forKey: "oruv_last_shielded_app_name"), !last.isEmpty {
            return last
        }

        return nil
    }

    private func recordConfirmedBlock(tokenKey: String, resolvedName: String?) {
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

        var effectiveName = resolvedName
        if effectiveName == nil || effectiveName?.isEmpty == true {
            effectiveName = resolveName(for: tokenKey)
        }

        tokenCounts[tokenKey, default: 0] += 1
        if let name = effectiveName, !name.isEmpty {
            tokenNames[tokenKey] = name
        }

        let mostBlocked = tokenCounts.max(by: { $0.value < $1.value })
        let topTokenKey = mostBlocked?.key ?? tokenKey
        let topCount = mostBlocked?.value ?? tokenCounts[tokenKey] ?? 1
        let topName: String = {
            if let name = tokenNames[topTokenKey], !name.isEmpty {
                return name
            }
            if let resolved = resolveName(for: topTokenKey), !resolved.isEmpty {
                return resolved
            }
            if topTokenKey == tokenKey, let name = effectiveName, !name.isEmpty {
                return name
            }
            return ""
        }()
        let total = tokenCounts.values.reduce(0, +)

        if let fileURL = fileURL {
            let payload: [String: Any] = [
                "date": todayStr,
                "tokenCounts": tokenCounts,
                "tokenNames": tokenNames,
                "mostBlockedTokenKey": topTokenKey,
                "mostBlockedAppName": topName,
                "mostBlockedCount": topCount,
                "total": total
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
                let coordinator = NSFileCoordinator(filePresenter: nil)
                coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: nil) { targetURL in
                    try? data.write(to: targetURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                    var mutableURL = targetURL
                    var values = URLResourceValues()
                    values.isExcludedFromBackup = true
                    try? mutableURL.setResourceValues(values)
                }
            }
        }

        sharedDefaults?.set(todayStr, forKey: "oruv_blocked_attempts_date")
        sharedDefaults?.set(tokenCounts, forKey: "oruv_blocked_token_counts")
        sharedDefaults?.set(tokenNames, forKey: "oruv_blocked_token_names")
        sharedDefaults?.set(topTokenKey, forKey: "oruv_most_blocked_token_key")
        sharedDefaults?.set(topName, forKey: "oruv_most_blocked_app_name")
        sharedDefaults?.set(topCount, forKey: "oruv_most_blocked_app_count")
        sharedDefaults?.set(total, forKey: "oruv_total_blocked_today")
        sharedDefaults?.synchronize()
    }

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        if let encoded = try? PropertyListEncoder().encode(application) {
            let tokenKey = "app:" + encoded.base64EncodedString()
            let name = Application(token: application).localizedDisplayName
            recordConfirmedBlock(tokenKey: tokenKey, resolvedName: name)
        }
        completionHandler(.close)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        if let encoded = try? PropertyListEncoder().encode(category) {
            let tokenKey = "cat:" + encoded.base64EncodedString()
            let name = ActivityCategory(token: category).localizedDisplayName
            recordConfirmedBlock(tokenKey: tokenKey, resolvedName: name)
        }
        completionHandler(.close)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        if let encoded = try? PropertyListEncoder().encode(webDomain) {
            let tokenKey = "web:" + encoded.base64EncodedString()
            let name = WebDomain(token: webDomain).domain
            recordConfirmedBlock(tokenKey: tokenKey, resolvedName: name)
        }
        completionHandler(.close)
    }
}

