import UIKit
import Flutter
import app_links

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    if let flutterViewController = storyboard.instantiateInitialViewController() as? FlutterViewController {
      window.rootViewController = flutterViewController
      self.window = window
      window.makeKeyAndVisible()

      if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
        appDelegate.window = window
        appDelegate.configureChannels(for: flutterViewController)
      }
    } else {
      self.window = window
      window.makeKeyAndVisible()
    }

    if let url = connectionOptions.urlContexts.first?.url {
      AppLinks.shared.handleLink(url: url)
    } else if let webpageURL = connectionOptions.userActivities.first?.webpageURL {
      AppLinks.shared.handleLink(url: webpageURL)
    }
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      AppLinks.shared.handleLink(url: context.url)
    }
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if let webpageURL = userActivity.webpageURL {
      AppLinks.shared.handleLink(url: webpageURL)
    }
  }

  func sceneDidDisconnect(_ scene: UIScene) {}
  func sceneDidBecomeActive(_ scene: UIScene) {
    #if canImport(FamilyControls)
    if #available(iOS 16.0, *) {
      ScreenTimeManager.shared.checkMindfulBreakExpiry()
    }
    #endif
  }
  func sceneWillResignActive(_ scene: UIScene) {}
  func sceneWillEnterForeground(_ scene: UIScene) {
    #if canImport(FamilyControls)
    if #available(iOS 16.0, *) {
      ScreenTimeManager.shared.checkMindfulBreakExpiry()
    }
    #endif
  }
  func sceneDidEnterBackground(_ scene: UIScene) {}
}
