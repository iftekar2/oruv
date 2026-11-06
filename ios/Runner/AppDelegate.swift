import Flutter
import UIKit
import SwiftUI
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

class DeviceActivityReportPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private var hostingController: UIViewController?

  init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
    self.containerView = UIView(frame: frame)
    self.containerView.backgroundColor = .white
    self.containerView.clipsToBounds = true
    super.init()

    #if canImport(DeviceActivity)
    if #available(iOS 16.0, *) {
      let swiftUIView = NativeDeviceActivityReportContainerView()
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
