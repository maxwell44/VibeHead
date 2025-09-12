//
//  ColorSystem.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI

/// 应用颜色系统，支持浅色和深色模式
extension Color {
    /// 健康绿色 - 用于优秀体态状态
    static let healthyGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    
    /// 警告橙色 - 用于不良体态警告
    static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    /// 警报红色 - 用于严重警告
    static let alertRed = Color(red: 0.9, green: 0.3, blue: 0.3)
    
    /// 主要蓝色 - 用于操作按钮
    static let primaryBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    /// 自适应背景色
    static let adaptiveBackground = Color(UIColor.systemBackground)
    
    /// 自适应文本色
    static let adaptiveText = Color(UIColor.label)
    
    /// 自适应次要文本色
    static let adaptiveSecondaryText = Color(UIColor.secondaryLabel)
    
    /// 自适应分组背景色
    static let adaptiveGroupedBackground = Color(UIColor.systemGroupedBackground)
    
    /// 根据体态类型获取对应颜色
    /// - Parameter postureType: 体态类型
    /// - Returns: 对应的颜色
    static func color(for postureType: PostureType) -> Color {
        return postureType.color
    }
}