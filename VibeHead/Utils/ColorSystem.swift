//
//  ColorSystem.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import UIKit

/// 应用颜色系统，支持浅色和深色模式
extension UIColor {
    /// 健康绿色 - 用于优秀体态状态
    static let healthyGreen = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
    
    /// 警告橙色 - 用于不良体态警告
    static let warningOrange = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
    
    /// 警报红色 - 用于严重警告
    static let alertRed = UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
    
    /// 主要蓝色 - 用于操作按钮
    static let primaryBlue = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
    
    /// 根据体态类型获取对应颜色
    /// - Parameter postureType: 体态类型
    /// - Returns: 对应的颜色
    static func color(for postureType: PostureType) -> UIColor {
        return postureType.color
    }
}