import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let viewController = ViewController()
        
        // Pass deep link URL if app cold-started via poke://inbox
        if let url = connectionOptions.urlContexts.first?.url {
            viewController.pendingDeepLink = url
        }
        
        window.rootViewController = viewController
        self.window = window
        window.makeKeyAndVisible()
    }

    // Handles poke://inbox deep link when app is running in background
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        if let viewController = window?.rootViewController as? ViewController {
            viewController.handleDeepLink(url)
        }
    }
}
