import UIKit
import Flutter

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
  }

  func sceneDidDisconnect(_ scene: UIScene) {}
  func sceneDidBecomeActive(_ scene: UIScene) {}
  func sceneWillResignActive(_ scene: UIScene) {}
  func sceneWillEnterForeground(_ scene: UIScene) {}
  func sceneDidEnterBackground(_ scene: UIScene) {}
}

