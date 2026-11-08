import Flutter
import UIKit
import SwiftUI
import Combine
#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
#endif
#if canImport(DeviceActivity)
import DeviceActivity
#endif

#if canImport(FamilyControls)
@available(iOS 16.0, *)
class ScreenTimeManager: ObservableObject {
  static let shared = ScreenTimeManager()
  static let appGroupId = "group.app.iftekarhossain.oruv"
  private let storageKey = "oruv_family_activity_selection"
  private let store = ManagedSettingsStore()

  var methodChannel: FlutterMethodChannel?
  var isShieldActive: Bool = true

  @Published private(set) var orderedAppTokens: [ApplicationToken] = []
  @Published private(set) var orderedCategoryTokens: [ActivityCategoryToken] = []
  @Published var mostBlockedAppToken: ApplicationToken? = nil
  @Published var mostBlockedCategoryToken: ActivityCategoryToken? = nil

  @Published var activitySelection = FamilyActivitySelection() {
    didSet {
      refreshOrderedTokens()
      saveSelection()
      notifyFlutter()
      if isShieldActive {
        applyShield()
      }
      startDailyDeviceActivityMonitoring()
    }
  }

  private init() {
    if let data = UserDefaults.standard.data(forKey: storageKey),
       let decoded = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
      self.activitySelection = decoded
      refreshOrderedTokens()
    }
  }

  private func refreshOrderedTokens() {
    orderedAppTokens = Array(activitySelection.applicationTokens)
    orderedCategoryTokens = Array(activitySelection.categoryTokens)
  }

  func saveSelection() {
    if let encoded = try? PropertyListEncoder().encode(activitySelection) {
      UserDefaults.standard.set(encoded, forKey: storageKey)
      UserDefaults(suiteName: Self.appGroupId)?.set(encoded, forKey: storageKey)
    }
  }

  func notifyFlutter() {
    let appsCount = orderedAppTokens.count
    let categoriesCount = orderedCategoryTokens.count
    let domainsCount = activitySelection.webDomainTokens.count
    let totalCount = appsCount + categoriesCount + domainsCount

    DispatchQueue.main.async { [weak self] in
      self?.methodChannel?.invokeMethod("onSelectionChanged", arguments: [
        "appsCount": appsCount,
        "categoriesCount": categoriesCount,
        "domainsCount": domainsCount,
        "totalCount": totalCount
      ])
    }
  }

  func applyShield() {
    isShieldActive = true
    store.shield.applications = activitySelection.applicationTokens.isEmpty
      ? nil
      : activitySelection.applicationTokens
    store.shield.applicationCategories = activitySelection.categoryTokens.isEmpty
      ? nil
      : .specific(activitySelection.categoryTokens)
    store.shield.webDomains = activitySelection.webDomainTokens.isEmpty
      ? nil
      : activitySelection.webDomainTokens
  }

  func clearShield() {
    isShieldActive = false
    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
  }

  func syncShield(shouldBlock: Bool) {
    if shouldBlock {
      applyShield()
    } else {
      clearShield()
    }
  }

  func startDailyDeviceActivityMonitoring() {
    #if canImport(DeviceActivity)
    guard AuthorizationCenter.shared.authorizationStatus == .approved else { return }
    let center = DeviceActivityCenter()
    let activityName = DeviceActivityName("oruv.daily.activity")
    let schedule = DeviceActivitySchedule(
      intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
      intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
      repeats: true
    )
    do {
      try center.startMonitoring(activityName, during: schedule)
    } catch {
      // Monitoring already active or requires physical device
    }
    #endif
  }
}

@available(iOS 16.0, *)
struct NativeFamilyActivityPickerView: View {
  @ObservedObject var manager = ScreenTimeManager.shared

  var body: some View {
    FamilyActivityPicker(selection: $manager.activitySelection)
      .preferredColorScheme(.dark)
      .background(Color(red: 0.11, green: 0.11, blue: 0.12))
  }
}

@available(iOS 16.0, *)
struct NativeSelectedAppsIconsView: View {
  @ObservedObject var manager = ScreenTimeManager.shared
  var alignLeft: Bool = false

  var body: some View {
    let appTokens = manager.orderedAppTokens
    let catTokens = manager.orderedCategoryTokens
    let domainTokens = Array(manager.activitySelection.webDomainTokens)
    let totalCount = appTokens.count + catTokens.count + domainTokens.count

    let maxIcons = 3
    let displayedApps = Array(appTokens.prefix(maxIcons))
    let remainingSlots = max(0, maxIcons - displayedApps.count)
    let displayedCats = Array(catTokens.prefix(remainingSlots))
    let shownCount = displayedApps.count + displayedCats.count
    let extraCount = max(0, totalCount - shownCount)

    HStack(alignment: .center, spacing: -5) {
      ForEach(displayedApps, id: \.self) { token in
        Label(token)
          .labelStyle(.iconOnly)
          .frame(width: 24, height: 24, alignment: .center)
          .background(Color.white)
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
      }
      ForEach(displayedCats, id: \.self) { token in
        Label(token)
          .labelStyle(.iconOnly)
          .frame(width: 24, height: 24, alignment: .center)
          .background(Color(red: 0.95, green: 0.95, blue: 0.96))
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
      }
      if extraCount > 0 {
        Text("+\(extraCount)")
          .font(.system(size: 9.5, weight: .bold))
          .foregroundColor(Color(red: 0.12, green: 0.10, blue: 0.11))
          .frame(minWidth: 24, minHeight: 24, alignment: .center)
          .padding(.horizontal, 4)
          .background(Color(red: 0.93, green: 0.91, blue: 0.90))
          .clipShape(Capsule())
          .overlay(Capsule().stroke(Color.white, lineWidth: 1.5))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignLeft ? .leading : .trailing)
    .background(Color.white)
    .ignoresSafeArea(.all)
  }
}

/// Renders a single real iOS App or Category icon from Apple's FamilyControls token.
@available(iOS 16.0, *)
struct NativeAppTokenIconView: View {
  @ObservedObject var manager = ScreenTimeManager.shared
  let tokenIndex: Int
  let isCategory: Bool

  var body: some View {
    Group {
      if isCategory {
        if tokenIndex >= 0 && tokenIndex < manager.orderedCategoryTokens.count {
          Label(manager.orderedCategoryTokens[tokenIndex])
            .labelStyle(.iconOnly)
            .scaleEffect(1.15)
        } else {
          Image(systemName: "square.grid.2x2.fill")
            .foregroundColor(Color(red: 0.43, green: 0.42, blue: 0.43))
        }
      } else {
        if tokenIndex >= 0 && tokenIndex < manager.orderedAppTokens.count {
          Label(manager.orderedAppTokens[tokenIndex])
            .labelStyle(.iconOnly)
            .scaleEffect(1.15)
        } else {
          Image(systemName: "app.fill")
            .foregroundColor(Color(red: 0.43, green: 0.42, blue: 0.43))
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(Color.white)
    .ignoresSafeArea(.all)
  }
}

/// Renders a single real iOS App or Category name from Apple's FamilyControls token.
@available(iOS 16.0, *)
struct NativeAppTokenTitleView: View {
  @ObservedObject var manager = ScreenTimeManager.shared
  let tokenIndex: Int
  let isCategory: Bool

  var body: some View {
    Group {
      if isCategory {
        if tokenIndex >= 0 && tokenIndex < manager.orderedCategoryTokens.count {
          Label(manager.orderedCategoryTokens[tokenIndex])
            .labelStyle(.titleOnly)
            .font(.system(size: 13.5, weight: .semibold, design: .serif))
            .foregroundColor(Color(red: 0.106, green: 0.106, blue: 0.114))
            .lineLimit(1)
        } else {
          Text("Category \(tokenIndex + 1)")
            .font(.system(size: 13.5, weight: .semibold, design: .serif))
            .foregroundColor(Color(red: 0.106, green: 0.106, blue: 0.114))
            .lineLimit(1)
        }
      } else {
        if tokenIndex >= 0 && tokenIndex < manager.orderedAppTokens.count {
          Label(manager.orderedAppTokens[tokenIndex])
            .labelStyle(.titleOnly)
            .font(.system(size: 13.5, weight: .semibold, design: .serif))
            .foregroundColor(Color(red: 0.106, green: 0.106, blue: 0.114))
            .lineLimit(1)
        } else {
          Text("App \(tokenIndex + 1)")
            .font(.system(size: 13.5, weight: .semibold, design: .serif))
            .foregroundColor(Color(red: 0.106, green: 0.106, blue: 0.114))
            .lineLimit(1)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(Color.white)
    .ignoresSafeArea(.all)
  }
}

#if canImport(DeviceActivity)
/// Hosts Apple's `DeviceActivityReport` view for full system-wide Screen Time reporting.
@available(iOS 16.0, *)
struct NativeDeviceActivityReportContainerView: View {
  var body: some View {
    let startOfDay = Calendar.current.startOfDay(for: Date())
    let interval = DateInterval(start: startOfDay, end: Date())
    let filter = DeviceActivityFilter(
      segment: .daily(during: interval),
      users: .all,
      devices: .init([.iPhone, .iPad])
    )
    DeviceActivityReport(
      DeviceActivityReport.Context("DailyScreenTime"),
      filter: filter
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
    .ignoresSafeArea(.all)
    .allowsHitTesting(false)
  }
}

/// Hosts Apple's `DeviceActivityReport` view for the full interactive Insights tab.
@available(iOS 16.0, *)
struct NativeInsightsReportContainerView: View {
  var body: some View {
    let startOfDay = Calendar.current.startOfDay(for: Date())
    let interval = DateInterval(start: startOfDay, end: Date())
    let filter = DeviceActivityFilter(
      segment: .daily(during: interval),
      users: .all,
      devices: .init([.iPhone, .iPad])
    )
    DeviceActivityReport(
      DeviceActivityReport.Context("InsightsScreenTime"),
      filter: filter
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
    .ignoresSafeArea(.all)
  }
}
#endif

class FamilyActivityPickerPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private var hostingController: UIViewController?

  init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
    self.containerView = UIView(frame: frame)
    self.containerView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
    super.init()

    #if canImport(FamilyControls)
    if #available(iOS 16.0, *) {
      let swiftUIView = NativeFamilyActivityPickerView()
      let hosting = UIHostingController(rootView: swiftUIView)
      hosting.view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
      hosting.view.translatesAutoresizingMaskIntoConstraints = false
      self.containerView.addSubview(hosting.view)

      NSLayoutConstraint.activate([
        hosting.view.topAnchor.constraint(equalTo: self.containerView.topAnchor),
        hosting.view.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
        hosting.view.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
        hosting.view.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor)
      ])
      self.hostingController = hosting
    }
    #endif
  }

  func view() -> UIView {
    return containerView
  }
}

class SelectedAppsIconsPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private var hostingController: UIViewController?

  init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
    self.containerView = UIView(frame: frame)
    self.containerView.backgroundColor = .white
    self.containerView.clipsToBounds = true
    super.init()

    #if canImport(FamilyControls)
    if #available(iOS 16.0, *) {
      let params = args as? [String: Any]
      let alignLeft = (params?["alignLeft"] as? Bool) ?? false
      let swiftUIView = NativeSelectedAppsIconsView(alignLeft: alignLeft)
      let hosting = UIHostingController(rootView: swiftUIView)
      if #available(iOS 16.4, *) {
        hosting.safeAreaRegions = []
      }
      hosting.view.backgroundColor = .white
      hosting.view.clipsToBounds = true
      hosting.view.insetsLayoutMarginsFromSafeArea = false
      hosting.view.translatesAutoresizingMaskIntoConstraints = false
      self.containerView.addSubview(hosting.view)

      NSLayoutConstraint.activate([
        hosting.view.topAnchor.constraint(equalTo: self.containerView.topAnchor),
        hosting.view.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
        hosting.view.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
        hosting.view.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor)
      ])
      self.hostingController = hosting
    }
    #endif
  }

  func view() -> UIView {
    return containerView
  }
}

class AppTokenIconPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private var hostingController: UIViewController?

  init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
    self.containerView = UIView(frame: frame)
    self.containerView.backgroundColor = .white
    self.containerView.clipsToBounds = true
    super.init()

    #if canImport(FamilyControls)
    if #available(iOS 16.0, *) {
      let params = args as? [String: Any]
      let index = (params?["index"] as? Int) ?? 0
      let isCategory = (params?["isCategory"] as? Bool) ?? false
      let swiftUIView = NativeAppTokenIconView(tokenIndex: index, isCategory: isCategory)
      let hosting = UIHostingController(rootView: swiftUIView)
      if #available(iOS 16.4, *) {
        hosting.safeAreaRegions = []
      }
      hosting.view.backgroundColor = .white
      hosting.view.clipsToBounds = true
      hosting.view.insetsLayoutMarginsFromSafeArea = false
      hosting.view.translatesAutoresizingMaskIntoConstraints = false
      self.containerView.addSubview(hosting.view)

      NSLayoutConstraint.activate([
        hosting.view.topAnchor.constraint(equalTo: self.containerView.topAnchor),
        hosting.view.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
        hosting.view.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
        hosting.view.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor)
      ])
      self.hostingController = hosting
    }
    #endif
  }

  func view() -> UIView {
    return containerView
  }
}

class AppTokenTitlePlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private var hostingController: UIViewController?

  init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
    self.containerView = UIView(frame: frame)
    self.containerView.backgroundColor = .white
    self.containerView.clipsToBounds = true
    super.init()

    #if canImport(FamilyControls)
    if #available(iOS 16.0, *) {
      let params = args as? [String: Any]
      let index = (params?["index"] as? Int) ?? 0
      let isCategory = (params?["isCategory"] as? Bool) ?? false
      let swiftUIView = NativeAppTokenTitleView(tokenIndex: index, isCategory: isCategory)
      let hosting = UIHostingController(rootView: swiftUIView)
      if #available(iOS 16.4, *) {
        hosting.safeAreaRegions = []
      }
      hosting.view.backgroundColor = .white
      hosting.view.clipsToBounds = true
      hosting.view.insetsLayoutMarginsFromSafeArea = false
      hosting.view.translatesAutoresizingMaskIntoConstraints = false
      self.containerView.addSubview(hosting.view)

      NSLayoutConstraint.activate([
        hosting.view.topAnchor.constraint(equalTo: self.containerView.topAnchor),
        hosting.view.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
        hosting.view.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
        hosting.view.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor)
      ])
      self.hostingController = hosting
    }
    #endif
  }

  func view() -> UIView {
    return containerView
  }
}

class DeviceActivityContainerView: UIView {
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    return nil
  }
}

class DeviceActivityReportPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private var hostingController: UIViewController?

  init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
    self.containerView = DeviceActivityContainerView(frame: frame)
    self.containerView.backgroundColor = .white
    self.containerView.clipsToBounds = true
    self.containerView.isUserInteractionEnabled = false
    super.init()

    #if canImport(DeviceActivity)
    if #available(iOS 16.0, *) {
      let swiftUIView = NativeDeviceActivityReportContainerView()
      let hosting = UIHostingController(rootView: swiftUIView)
      hosting.view.isUserInteractionEnabled = false
      if #available(iOS 16.4, *) {
        hosting.safeAreaRegions = []
      }
      hosting.view.backgroundColor = .white
      hosting.view.clipsToBounds = true
      hosting.view.insetsLayoutMarginsFromSafeArea = false
      hosting.view.translatesAutoresizingMaskIntoConstraints = false
      self.containerView.addSubview(hosting.view)

      NSLayoutConstraint.activate([
        hosting.view.topAnchor.constraint(equalTo: self.containerView.topAnchor),
        hosting.view.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
        hosting.view.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
        hosting.view.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor)
      ])
      self.hostingController = hosting
    }
    #endif
  }

  func view() -> UIView {
    return containerView
  }
}

class InsightsActivityReportPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private var hostingController: UIViewController?

  init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
    self.containerView = UIView(frame: frame)
    self.containerView.backgroundColor = .white
    self.containerView.clipsToBounds = true
    self.containerView.isUserInteractionEnabled = true
    super.init()

    #if canImport(DeviceActivity)
    if #available(iOS 16.0, *) {
      let swiftUIView = NativeInsightsReportContainerView()
      let hosting = UIHostingController(rootView: swiftUIView)
      hosting.view.isUserInteractionEnabled = true
      if #available(iOS 16.4, *) {
        hosting.safeAreaRegions = []
      }
      hosting.view.backgroundColor = .white
      hosting.view.clipsToBounds = true
      hosting.view.insetsLayoutMarginsFromSafeArea = false
      hosting.view.translatesAutoresizingMaskIntoConstraints = false
      self.containerView.addSubview(hosting.view)

      NSLayoutConstraint.activate([
        hosting.view.topAnchor.constraint(equalTo: self.containerView.topAnchor),
        hosting.view.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
        hosting.view.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
        hosting.view.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor)
      ])
      self.hostingController = hosting
    }
    #endif
  }

  func view() -> UIView {
    return containerView
  }
}

class FamilyActivityPickerFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return FamilyActivityPickerPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class SelectedAppsIconsFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return SelectedAppsIconsPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class AppTokenIconFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return AppTokenIconPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class AppTokenTitleFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return AppTokenTitlePlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

@available(iOS 16.0, *)
func extractAppName(from token: ApplicationToken) -> String? {
  // Method 1: Check known app names in app_names.json
  if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ScreenTimeManager.appGroupId) {
    let namesURL = containerURL.appendingPathComponent("app_names.json")
    if let data = try? Data(contentsOf: namesURL),
       let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
      if let encoded = try? PropertyListEncoder().encode(token) {
        let key = "app:" + encoded.base64EncodedString()
        if let name = dict[key], !name.isEmpty, name != "App", name != "This app" {
          return name
        }
      }
      if let last = dict["last"], !last.isEmpty, last != "App", last != "This app" {
        return last
      }
    }
  }

  // Method 2: Check shared UserDefaults
  let sharedDefaults = UserDefaults(suiteName: ScreenTimeManager.appGroupId)
  if let encoded = try? PropertyListEncoder().encode(token) {
    let key = "app:" + encoded.base64EncodedString()
    if let names = sharedDefaults?.dictionary(forKey: "oruv_blocked_token_names") as? [String: String],
       let name = names[key], !name.isEmpty, name != "App" {
      return name
    }
  }
  if let last = sharedDefaults?.string(forKey: "oruv_last_shielded_app_name"), !last.isEmpty, last != "App" {
    return last
  }

  // Method 3: Inspect hosting controller view hierarchy & accessibility
  let controller = UIHostingController(rootView: Label(token).labelStyle(.titleOnly))
  controller.overrideUserInterfaceStyle = .light
  let view = controller.view!
  view.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
  view.layoutIfNeeded()

  func findText(in uiview: UIView) -> String? {
    if let label = uiview.accessibilityLabel, !label.isEmpty, label != "App", label != "This app" {
      return label
    }
    if let uilabel = uiview as? UILabel, let text = uilabel.text, !text.isEmpty, text != "App" {
      return text
    }
    for sub in uiview.subviews {
      if let found = findText(in: sub) {
        return found
      }
    }
    return nil
  }

  if let found = findText(in: view) {
    return found
  }

  return nil
}

/// Renders a single raw FamilyControls title slot with width=0 so FamilyControlsAgent
/// uses `Double.nan` for `UISTextLineDrawing` and returns the exact `CTLineGetTypographicBounds`
/// as `_UISlotView.intrinsicContentSize` without trailing whitespace.
@available(iOS 16.0, *)
struct SingleSlotTokenView: View {
  @ObservedObject var manager = ScreenTimeManager.shared

  var body: some View {
    Group {
      if let appToken = manager.mostBlockedAppToken {
        Label(appToken)
          .labelStyle(.titleOnly)
      } else if let catToken = manager.mostBlockedCategoryToken {
        Label(catToken)
          .labelStyle(.titleOnly)
      }
    }
    .frame(width: 0, height: 25, alignment: .topLeading)
    .environment(\.sizeCategory, .extraSmall)
    .environment(\.colorScheme, .light)
  }
}

/// Custom UIKit container that extracts `_UISlotView.intrinsicContentSize` (exact pixel width & height
/// of the app name from `FamilyControlsAgent`), renders 4 sub-pixel-offset copies for a crisp bold weight,
/// scales the slot so its height matches `"Blocked"` 1:1, and centers `"<AppName> Blocked"` with zero gap.
@available(iOS 16.0, *)
class MostBlockedAppTitleContainerView: UIView {
  private let slotWrapperView = UIView()
  private var hostingControllers: [UIHostingController<SingleSlotTokenView>] = []
  private var slotViews: [UIView] = []
  private let blockedLabel = UILabel()
  private var layoutTimer: Timer?
  private var cancellables = Set<AnyCancellable>()

  // Sub-pixel offsets in unscaled slot coordinates (14pt SF Pro) to synthesize SF Pro Bold weight
  private let boldOffsets: [CGPoint] = [
    CGPoint(x: 0.0, y: 0.0),
    CGPoint(x: 0.45, y: 0.0),
    CGPoint(x: 0.90, y: 0.0),
    CGPoint(x: 0.45, y: 0.20)
  ]

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViews()
  }

  private func setupViews() {
    backgroundColor = .white
    clipsToBounds = true
    isUserInteractionEnabled = false
    overrideUserInterfaceStyle = .light

    slotWrapperView.backgroundColor = .clear
    slotWrapperView.clipsToBounds = false
    slotWrapperView.layer.anchorPoint = CGPoint(x: 0, y: 0)
    addSubview(slotWrapperView)

    for offset in boldOffsets {
      let hosting = UIHostingController(rootView: SingleSlotTokenView())
      hosting.overrideUserInterfaceStyle = .light
      if #available(iOS 16.4, *) {
        hosting.safeAreaRegions = []
      }
      hosting.view.backgroundColor = .clear
      hosting.view.clipsToBounds = false
      hosting.view.insetsLayoutMarginsFromSafeArea = false
      hosting.view.frame = CGRect(x: offset.x, y: offset.y, width: 0, height: 25)
      slotWrapperView.addSubview(hosting.view)
      hostingControllers.append(hosting)
    }

    blockedLabel.text = "Blocked"
    blockedLabel.font = UIFont.systemFont(ofSize: 11.5, weight: .regular)
    blockedLabel.textColor = UIColor(red: 0.106, green: 0.106, blue: 0.114, alpha: 1.0)
    blockedLabel.backgroundColor = .clear
    blockedLabel.numberOfLines = 1
    blockedLabel.sizeToFit()
    addSubview(blockedLabel)

    ScreenTimeManager.shared.$mostBlockedAppToken
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.resetAndPollSlotMetrics()
      }
      .store(in: &cancellables)

    ScreenTimeManager.shared.$mostBlockedCategoryToken
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.resetAndPollSlotMetrics()
      }
      .store(in: &cancellables)

    startPollingSlotMetrics()
  }

  private func resetAndPollSlotMetrics() {
    slotViews.removeAll()
    for (index, hosting) in hostingControllers.enumerated() {
      let offset = boldOffsets[index]
      hosting.view.frame = CGRect(x: offset.x, y: offset.y, width: 0, height: 25)
      hosting.view.setNeedsLayout()
    }
    startPollingSlotMetrics()
  }

  private func startPollingSlotMetrics() {
    layoutTimer?.invalidate()
    var ticks = 0
    layoutTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }
      ticks += 1
      self.prepareSlotHierarchyIfNeeded()
      self.updateExactLayout()
      if ticks > 60 {
        timer.invalidate()
      }
    }
  }

  private func findSlotView(in root: UIView) -> UIView? {
    let typeName = String(describing: type(of: root))
    if typeName.contains("SlotView") {
      return root
    }
    for sub in root.subviews {
      if let found = findSlotView(in: sub) {
        return found
      }
    }
    return nil
  }

  private func disableClippingRecursively(in view: UIView) {
    view.clipsToBounds = false
    view.backgroundColor = .clear
    for sub in view.subviews {
      disableClippingRecursively(in: sub)
    }
  }

  private func prepareSlotHierarchyIfNeeded() {
    for hosting in hostingControllers {
      disableClippingRecursively(in: hosting.view)
    }

    if slotViews.count < hostingControllers.count {
      slotViews.removeAll()
      for hosting in hostingControllers {
        hosting.view.layoutIfNeeded()
        if let slot = findSlotView(in: hosting.view) {
          // Deactivate trailing/bottom/width/height constraints on FamilyActivitySlot so _UISlotView
          // sizes itself strictly to its intrinsicContentSize (CTLineGetTypographicBounds of the app name).
          if let familySlot = slot.superview {
            for constraint in familySlot.constraints {
              if constraint.firstItem === slot || constraint.secondItem === slot {
                let a1 = constraint.firstAttribute
                let a2 = constraint.secondAttribute
                if a1 == .trailing || a1 == .right || a1 == .bottom || a1 == .width || a1 == .height ||
                   a2 == .trailing || a2 == .right || a2 == .bottom || a2 == .width || a2 == .height {
                  constraint.isActive = false
                }
              }
            }
            familySlot.setNeedsLayout()
            familySlot.layoutIfNeeded()
          }
          slot.setContentHuggingPriority(.required, for: .horizontal)
          slot.setContentHuggingPriority(.required, for: .vertical)
          slot.setContentCompressionResistancePriority(.required, for: .horizontal)
          slot.setContentCompressionResistancePriority(.required, for: .vertical)
          slotViews.append(slot)
        }
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    prepareSlotHierarchyIfNeeded()
    updateExactLayout()
  }

  private func updateExactLayout() {
    guard bounds.width > 0, bounds.height > 0 else { return }

    let hasToken = ScreenTimeManager.shared.mostBlockedAppToken != nil ||
                   ScreenTimeManager.shared.mostBlockedCategoryToken != nil

    blockedLabel.text = hasToken ? "Blocked" : "Urges Blocked"
    blockedLabel.sizeToFit()
    let blockedSize = blockedLabel.intrinsicContentSize

    guard hasToken, let primarySlot = slotViews.first else {
      slotWrapperView.isHidden = true
      blockedLabel.frame = CGRect(
        x: (bounds.width - blockedSize.width) / 2.0,
        y: (bounds.height - blockedSize.height) / 2.0,
        width: blockedSize.width,
        height: blockedSize.height
      )
      return
    }

    for slot in slotViews {
      slot.superview?.layoutIfNeeded()
      slot.layoutIfNeeded()
    }

    let intrinsic = primarySlot.intrinsicContentSize
    let rawWidth = max(intrinsic.width, primarySlot.bounds.width)
    let rawHeight = max(intrinsic.height, primarySlot.bounds.height)

    guard rawWidth > 1.0, rawHeight > 1.0 else {
      return
    }

    slotWrapperView.isHidden = false

    // Normalize each hosting.view origin so its _UISlotView sits at exact `boldOffsets[i]` inside slotWrapperView
    for (index, hosting) in hostingControllers.enumerated() {
      guard index < slotViews.count else { continue }
      let slot = slotViews[index]
      let offset = boldOffsets[index]
      let slotOriginInHosting = slot.convert(CGPoint.zero, to: hosting.view)
      hosting.view.frame = CGRect(
        x: offset.x - slotOriginInHosting.x,
        y: offset.y - slotOriginInHosting.y,
        width: 0,
        height: 25
      )
    }

    // Scale the slot so its rendered height is 100% identical to `blockedLabel`'s height
    var scale = blockedSize.height / rawHeight
    let rawBoldWidth = rawWidth + 0.90
    let spacing: CGFloat = 3.5

    let maxTotalWidth = max(20.0, bounds.width - 2.0)
    if (rawBoldWidth * scale) + spacing + blockedSize.width > maxTotalWidth {
      let availableForApp = max(16.0, maxTotalWidth - spacing - blockedSize.width)
      scale = availableForApp / rawBoldWidth
    }

    let finalAppWidth = rawBoldWidth * scale
    let finalAppHeight = rawHeight * scale
    let totalWidth = finalAppWidth + spacing + blockedSize.width
    let startX = max(0.0, (bounds.width - totalWidth) / 2.0)
    let appY = (bounds.height - finalAppHeight) / 2.0
    let blockedY = (bounds.height - blockedSize.height) / 2.0

    slotWrapperView.transform = .identity
    slotWrapperView.bounds = CGRect(x: 0, y: 0, width: rawBoldWidth, height: rawHeight)
    slotWrapperView.layer.position = CGPoint(x: startX, y: appY)
    slotWrapperView.transform = CGAffineTransform(scaleX: scale, y: scale)

    blockedLabel.frame = CGRect(
      x: startX + finalAppWidth + spacing,
      y: blockedY,
      width: blockedSize.width,
      height: blockedSize.height
    )
  }

  deinit {
    layoutTimer?.invalidate()
  }
}

class MostBlockedAppTitlePlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView

  init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
    #if canImport(FamilyControls)
    if #available(iOS 16.0, *) {
      self.containerView = MostBlockedAppTitleContainerView(frame: frame)
    } else {
      self.containerView = UIView(frame: frame)
    }
    #else
    self.containerView = UIView(frame: frame)
    #endif
    super.init()
  }

  func view() -> UIView {
    return containerView
  }
}

class MostBlockedAppTitleFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return MostBlockedAppTitlePlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class DeviceActivityReportFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return DeviceActivityReportPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class InsightsActivityReportFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return InsightsActivityReportPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let screenTimeChannel = FlutterMethodChannel(
        name: "oruv/screen_time",
        binaryMessenger: controller.binaryMessenger
      )

      #if canImport(FamilyControls)
      if #available(iOS 16.0, *) {
        ScreenTimeManager.shared.methodChannel = screenTimeChannel
      }
      if let registrar = self.registrar(forPlugin: "OruvFamilyActivityPicker") {
        let pickerFactory = FamilyActivityPickerFactory(messenger: registrar.messenger())
        registrar.register(pickerFactory, withId: "oruv/family_activity_picker")

        let iconsFactory = SelectedAppsIconsFactory(messenger: registrar.messenger())
        registrar.register(iconsFactory, withId: "oruv/selected_apps_icons")

        let singleIconFactory = AppTokenIconFactory(messenger: registrar.messenger())
        registrar.register(singleIconFactory, withId: "oruv/app_token_icon")

        let singleTitleFactory = AppTokenTitleFactory(messenger: registrar.messenger())
        registrar.register(singleTitleFactory, withId: "oruv/app_token_title")

        let reportFactory = DeviceActivityReportFactory(messenger: registrar.messenger())
        registrar.register(reportFactory, withId: "oruv/device_activity_report")

        let insightsReportFactory = InsightsActivityReportFactory(messenger: registrar.messenger())
        registrar.register(insightsReportFactory, withId: "oruv/insights_activity_report")

        let mostBlockedTitleFactory = MostBlockedAppTitleFactory(messenger: registrar.messenger())
        registrar.register(mostBlockedTitleFactory, withId: "oruv/most_blocked_app_title")
      }
      #endif

      screenTimeChannel.setMethodCallHandler { call, result in
        #if canImport(FamilyControls)
        if #available(iOS 16.0, *) {
          switch call.method {
          case "requestAuthorization":
            Task {
              do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                let isApproved = AuthorizationCenter.shared.authorizationStatus == .approved
                DispatchQueue.main.async {
                  ScreenTimeManager.shared.startDailyDeviceActivityMonitoring()
                  ScreenTimeManager.shared.notifyFlutter()
                  result([
                    "authorized": isApproved
                  ])
                }
              } catch {
                DispatchQueue.main.async {
                  result([
                    "authorized": false,
                    "error": error.localizedDescription
                  ])
                }
              }
            }
          case "checkAuthorizationStatus":
            let isApproved = AuthorizationCenter.shared.authorizationStatus == .approved
            result([
              "authorized": isApproved
            ])
          case "getBlockedAttempts":
            let sharedDefaults = UserDefaults(suiteName: ScreenTimeManager.appGroupId)
            sharedDefaults?.synchronize()

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayStr = formatter.string(from: Date())

            var topTokenKey = ""
            var appName = ""
            var count = 0
            var total = 0

            // 1. Read from shared App Group JSON file written by ShieldActionExtension
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ScreenTimeManager.appGroupId) {
              let fileURL = containerURL.appendingPathComponent("blocked_attempts.json")
              if let data = try? Data(contentsOf: fileURL),
                 let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                 (json["date"] as? String) == todayStr {
                topTokenKey = (json["mostBlockedTokenKey"] as? String) ?? ""
                appName = (json["mostBlockedAppName"] as? String) ?? ""
                count = (json["mostBlockedCount"] as? Int) ?? 0
                total = (json["total"] as? Int) ?? 0
              }
            }

            // 2. Fallback to UserDefaults if file was not found
            if count == 0 && sharedDefaults?.string(forKey: "oruv_blocked_attempts_date") == todayStr {
              let tokenCounts = (sharedDefaults?.dictionary(forKey: "oruv_blocked_token_counts") as? [String: Int]) ?? [:]
              if let mostBlocked = tokenCounts.max(by: { $0.value < $1.value }) {
                topTokenKey = mostBlocked.key
                count = mostBlocked.value
                total = tokenCounts.values.reduce(0, +)
              } else {
                topTokenKey = sharedDefaults?.string(forKey: "oruv_most_blocked_token_key") ?? ""
                count = sharedDefaults?.integer(forKey: "oruv_most_blocked_app_count") ?? 0
                total = sharedDefaults?.integer(forKey: "oruv_total_blocked_today") ?? 0
              }
              appName = sharedDefaults?.string(forKey: "oruv_most_blocked_app_name") ?? ""
            }

            // 3. Decode the ApplicationToken or ActivityCategoryToken so SwiftUI Label(token) can render its real name
            if topTokenKey.hasPrefix("app:") {
              let base64 = String(topTokenKey.dropFirst(4))
              if let data = Data(base64Encoded: base64),
                 let token = try? PropertyListDecoder().decode(ApplicationToken.self, from: data) {
                ScreenTimeManager.shared.mostBlockedAppToken = token
                ScreenTimeManager.shared.mostBlockedCategoryToken = nil
                if appName.isEmpty, let resolved = Application(token: token).localizedDisplayName, !resolved.isEmpty {
                  appName = resolved
                }
              }
            } else if topTokenKey.hasPrefix("cat:") {
              let base64 = String(topTokenKey.dropFirst(4))
              if let data = Data(base64Encoded: base64),
                 let token = try? PropertyListDecoder().decode(ActivityCategoryToken.self, from: data) {
                ScreenTimeManager.shared.mostBlockedCategoryToken = token
                ScreenTimeManager.shared.mostBlockedAppToken = nil
                if appName.isEmpty, let resolved = ActivityCategory(token: token).localizedDisplayName, !resolved.isEmpty {
                  appName = resolved
                }
              }
            } else if topTokenKey.hasPrefix("web:") {
              ScreenTimeManager.shared.mostBlockedAppToken = nil
              ScreenTimeManager.shared.mostBlockedCategoryToken = nil
              let base64 = String(topTokenKey.dropFirst(4))
              if let data = Data(base64Encoded: base64),
                 let token = try? PropertyListDecoder().decode(WebDomainToken.self, from: data),
                 appName.isEmpty,
                 let domain = WebDomain(token: token).domain {
                appName = domain
              }
            } else if count == 0 {
              ScreenTimeManager.shared.mostBlockedAppToken = nil
              ScreenTimeManager.shared.mostBlockedCategoryToken = nil
            }

            // 4. Resolve app name from shared app_names.json, token dictionary, or last shielded app name
            if appName.isEmpty {
              if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ScreenTimeManager.appGroupId) {
                let namesURL = containerURL.appendingPathComponent("app_names.json")
                if let data = try? Data(contentsOf: namesURL),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                  appName = dict[topTokenKey] ?? dict["last"] ?? ""
                }
              }
            }
            if appName.isEmpty {
              let savedTokenNames = (sharedDefaults?.dictionary(forKey: "oruv_blocked_token_names") as? [String: String]) ?? [:]
              appName = savedTokenNames[topTokenKey]
                ?? sharedDefaults?.string(forKey: "oruv_most_blocked_app_name")
                ?? ""
            }

            // 5. If still empty, inspect the native token view directly
            if appName.isEmpty, let token = ScreenTimeManager.shared.mostBlockedAppToken {
              if let resolved = extractAppName(from: token), !resolved.isEmpty {
                appName = resolved
                sharedDefaults?.set(resolved, forKey: "oruv_most_blocked_app_name")
                if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ScreenTimeManager.appGroupId) {
                  let fileURL = containerURL.appendingPathComponent("blocked_attempts.json")
                  if let data = try? Data(contentsOf: fileURL),
                     var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    json["mostBlockedAppName"] = resolved
                    if let updated = try? JSONSerialization.data(withJSONObject: json, options: []) {
                      try? updated.write(to: fileURL, options: .atomic)
                    }
                  }
                }
              }
            }

            let hasNativeToken = (ScreenTimeManager.shared.mostBlockedAppToken != nil
              || ScreenTimeManager.shared.mostBlockedCategoryToken != nil)

            result([
              "appName": appName,
              "count": count,
              "totalAttempts": total,
              "hasNativeToken": hasNativeToken
            ])
          case "resetBlockedAttempts":
            let sharedDefaults = UserDefaults(suiteName: ScreenTimeManager.appGroupId)
            sharedDefaults?.removeObject(forKey: "oruv_blocked_attempts_today")
            sharedDefaults?.removeObject(forKey: "oruv_blocked_token_counts")
            sharedDefaults?.removeObject(forKey: "oruv_blocked_token_names")
            sharedDefaults?.removeObject(forKey: "oruv_most_blocked_token_key")
            sharedDefaults?.removeObject(forKey: "oruv_most_blocked_app_name")
            sharedDefaults?.removeObject(forKey: "oruv_most_blocked_app_count")
            sharedDefaults?.removeObject(forKey: "oruv_total_blocked_today")
            sharedDefaults?.removeObject(forKey: "oruv_last_open_timestamps")
            sharedDefaults?.removeObject(forKey: "oruv_last_shielded_app_name")
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ScreenTimeManager.appGroupId) {
              let fileURL = containerURL.appendingPathComponent("blocked_attempts.json")
              try? FileManager.default.removeItem(at: fileURL)
              let namesURL = containerURL.appendingPathComponent("app_names.json")
              try? FileManager.default.removeItem(at: namesURL)
            }
            sharedDefaults?.synchronize()
            ScreenTimeManager.shared.mostBlockedAppToken = nil
            ScreenTimeManager.shared.mostBlockedCategoryToken = nil
            result(true)
          case "getDailyScreenTime":
            let isApproved = AuthorizationCenter.shared.authorizationStatus == .approved
            let appsCount = ScreenTimeManager.shared.orderedAppTokens.count
            let categoriesCount = ScreenTimeManager.shared.orderedCategoryTokens.count
            let domainsCount = ScreenTimeManager.shared.activitySelection.webDomainTokens.count
            let sharedDefaults = UserDefaults(suiteName: ScreenTimeManager.appGroupId)
            let cachedTotalMinutes = sharedDefaults?.integer(forKey: "oruv_daily_total_minutes") ?? 0
            let cachedApps = (sharedDefaults?.array(forKey: "oruv_daily_apps") as? [[String: Any]]) ?? []

            result([
              "authorized": isApproved,
              "appsCount": appsCount,
              "categoriesCount": categoriesCount,
              "domainsCount": domainsCount,
              "totalMinutes": cachedTotalMinutes,
              "apps": cachedApps
            ])
          case "applyShield":
            ScreenTimeManager.shared.applyShield()
            result(true)
          case "clearShield":
            ScreenTimeManager.shared.clearShield()
            result(true)
          case "syncShield":
            let args = call.arguments as? [String: Any]
            let shouldBlock = (args?["shouldBlock"] as? Bool) ?? true
            let sharedDefaults = UserDefaults(suiteName: ScreenTimeManager.appGroupId)
            if let sessionRemaining = args?["sessionRemaining"] as? String {
              sharedDefaults?.set(sessionRemaining, forKey: "oruv_session_remaining")
            }
            if let protectedToday = args?["protectedToday"] as? String {
              sharedDefaults?.set(protectedToday, forKey: "oruv_protected_today")
            }
            if let screenTimeToday = args?["screenTimeToday"] as? String {
              sharedDefaults?.set(screenTimeToday, forKey: "oruv_screen_time_today")
            }
            if let scheduleTitle = args?["scheduleTitle"] as? String {
              sharedDefaults?.set(scheduleTitle, forKey: "oruv_schedule_title")
            }
            if let projectedTimeText = args?["projectedTimeText"] as? String {
              sharedDefaults?.set(projectedTimeText, forKey: "oruv_projected_time")
            }
            if let projectedLabel = args?["projectedLabel"] as? String {
              sharedDefaults?.set(projectedLabel, forKey: "oruv_projected_label")
            }
            if let isSavingTime = args?["isSavingTime"] as? Bool {
              sharedDefaults?.set(isSavingTime, forKey: "oruv_is_saving_time")
            }
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ScreenTimeManager.appGroupId) {
              let metricsURL = containerURL.appendingPathComponent("insights_metrics.json")
              var metricsDict: [String: Any] = [:]
              if let baselineMinutes = args?["baselineMinutes"] as? Int {
                metricsDict["baselineMinutes"] = baselineMinutes
              }
              if let elapsedSavedMinutes = args?["elapsedSavedMinutes"] as? Int {
                metricsDict["elapsedSavedMinutes"] = elapsedSavedMinutes
              }
              if let projectedTimeText = args?["projectedTimeText"] as? String {
                metricsDict["projectedTimeText"] = projectedTimeText
              }
              if !metricsDict.isEmpty, let data = try? JSONSerialization.data(withJSONObject: metricsDict, options: []) {
                try? data.write(to: metricsURL, options: .atomic)
              }
            }
            ScreenTimeManager.shared.syncShield(shouldBlock: shouldBlock)
            result(true)
          default:
            result(FlutterMethodNotImplemented)
          }
          return
        }
        #endif
        result([
          "authorized": false,
          "error": "Screen Time API requires iOS 16.0 or newer."
        ])
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
