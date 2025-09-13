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
        print("🚀 SceneDelegate: scene willConnectTo called")
        
        guard let windowScene = (scene as? UIWindowScene) else { 
            print("❌ SceneDelegate: Failed to cast scene to UIWindowScene")
            return 
        }
        
        print("🚀 SceneDelegate: WindowScene obtained successfully")
        
        // 创建最简单的测试视图控制器
        let testViewController = UIViewController()
        testViewController.view.backgroundColor = .red
        testViewController.title = "Test"
        
        print("🚀 SceneDelegate: Test view controller created")
        
        // 创建窗口
        window = UIWindow(windowScene: windowScene)
        print("🚀 SceneDelegate: Window created")
        
        // 设置根视图控制器
        window?.rootViewController = createRootViewController()
        print("🚀 SceneDelegate: Root view controller set")
        
        // 显示窗口
        window?.makeKeyAndVisible()
        print("🚀 SceneDelegate: Window made key and visible")
        
        // 验证窗口状态
        print("🚀 SceneDelegate: Window frame: \(window?.frame ?? .zero)")
        print("🚀 SceneDelegate: Window isHidden: \(window?.isHidden ?? true)")
        print("🚀 SceneDelegate: Window isKeyWindow: \(window?.isKeyWindow ?? false)")
    }
    
    // MARK: - Private Methods
    
    private func createRootViewController() -> UIViewController {
        // 使用新的WorkSessionViewController作为根视图控制器
        let workSessionViewController = WorkSessionViewController()
        workSessionViewController.view.backgroundColor = .red
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

