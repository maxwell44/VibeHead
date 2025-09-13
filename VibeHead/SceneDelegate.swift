//
//  SceneDelegate.swift
//  VibeHead
//
//  Created by Maxwell Yu on 2025/9/12.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        print("🚀 SceneDelegate: Starting UIKit scene setup")
        
        // 创建UIKit根视图控制器
        let rootViewController = createRootViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        
        // 配置导航栏外观
        configureNavigationBarAppearance(navigationController)
        
        // 设置窗口
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        print("🚀 SceneDelegate: UIKit window setup completed")
    }
    
    // MARK: - Private Methods
    
    private func createRootViewController() -> UIViewController {
        // 使用新的WorkSessionViewController作为根视图控制器
        let workSessionViewController = WorkSessionViewController()
        return workSessionViewController
    }

    
    private func configureNavigationBarAppearance(_ navigationController: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        
        navigationController.navigationBar.tintColor = .systemBlue
        navigationController.navigationBar.prefersLargeTitles = false
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

