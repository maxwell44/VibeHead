//
//  AppDelegate.swift
//  VibeHead
//
//  Created by Maxwell Yu on 2025/9/12.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("🚀 AppDelegate: UIKit应用启动")
        
        // 配置应用级别的外观和行为
        configureAppearance()
        
        // 如果没有Scene支持，直接在这里创建窗口
        if #available(iOS 13.0, *) {
            // iOS 13+ 使用Scene
            print("🚀 AppDelegate: iOS 13+ - 使用Scene")
        } else {
            // iOS 12 及以下版本的窗口设置
            print("🚀 AppDelegate: iOS 12- - 直接设置窗口")
            setupWindowForOlderiOS()
        }
        
        return true
    }
    
    private func setupWindowForOlderiOS() {
        window = UIWindow(frame: UIScreen.main.bounds)
        let testViewController = UIViewController()
        testViewController.view.backgroundColor = .blue
        testViewController.title = "AppDelegate Test"
        
        window?.rootViewController = testViewController
        window?.makeKeyAndVisible()
        
        print("🚀 AppDelegate: 旧版iOS窗口设置完成")
    }
    
    // MARK: - Private Methods
    
    private func configureAppearance() {
        // 配置全局外观
        if #available(iOS 15.0, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0
        }
        
        // 配置状态栏样式
        UIApplication.shared.statusBarStyle = .default
        
        print("🚀 AppDelegate: 全局外观配置完成")
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

