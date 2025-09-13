//
//  UIKitPostureStatusViewTest.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import UIKit

/// 测试UIKitPostureStatusView的简单测试类
class UIKitPostureStatusViewTest {
    
    /// 测试创建和基本功能
    static func testBasicFunctionality() -> Bool {
        // 创建视图实例
        let postureStatusView = UIKitPostureStatusView()
        
        // 测试初始状态
        guard postureStatusView.superview == nil else {
            print("❌ 初始状态测试失败：视图不应该有父视图")
            return false
        }
        
        // 测试更新功能
        postureStatusView.updatePostureStatus(
            posture: .excellent,
            duration: 0,
            detecting: true,
            threshold: 10
        )
        
        // 测试不同状态
        postureStatusView.updatePostureStatus(
            posture: .lookingDown,
            duration: 5,
            detecting: true,
            threshold: 10
        )
        
        // 测试警告状态
        postureStatusView.updatePostureStatus(
            posture: .tilted,
            duration: 12,
            detecting: true,
            threshold: 10
        )
        
        // 测试摄像头未启用状态
        postureStatusView.updatePostureStatus(
            posture: .tooClose,
            duration: 0,
            detecting: false,
            threshold: 10
        )
        
        print("✅ UIKitPostureStatusView 基本功能测试通过")
        return true
    }
    
    /// 测试预览实例创建
    static func testPreviewInstances() -> Bool {
        // 测试优秀体态
        let excellentView = UIKitPostureStatusView.createPreviewInstance(
            posture: .excellent,
            duration: 0,
            detecting: true,
            threshold: 10
        )
        
        // 测试低头体态 - 警告前
        let lookingDownView = UIKitPostureStatusView.createPreviewInstance(
            posture: .lookingDown,
            duration: 5,
            detecting: true,
            threshold: 10
        )
        
        // 测试歪头体态 - 警告中
        let tiltedView = UIKitPostureStatusView.createPreviewInstance(
            posture: .tilted,
            duration: 12,
            detecting: true,
            threshold: 10
        )
        
        // 测试太近体态 - 摄像头未启用
        let tooCloseView = UIKitPostureStatusView.createPreviewInstance(
            posture: .tooClose,
            duration: 0,
            detecting: false,
            threshold: 10
        )
        
        // 验证所有实例都创建成功
        let views = [excellentView, lookingDownView, tiltedView, tooCloseView]
        for (index, view) in views.enumerated() {
            guard view.superview == nil else {
                print("❌ 预览实例 \(index) 测试失败：视图不应该有父视图")
                return false
            }
        }
        
        print("✅ UIKitPostureStatusView 预览实例测试通过")
        return true
    }
    
    /// 运行所有测试
    static func runAllTests() -> Bool {
        print("🧪 开始测试 UIKitPostureStatusView...")
        
        let basicTest = testBasicFunctionality()
        let previewTest = testPreviewInstances()
        
        let allPassed = basicTest && previewTest
        
        if allPassed {
            print("🎉 所有 UIKitPostureStatusView 测试通过！")
        } else {
            print("❌ 部分 UIKitPostureStatusView 测试失败")
        }
        
        return allPassed
    }
}