//
//  AppSettings.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation

/// 应用设置模型，管理用户偏好设置
struct AppSettings: Codable {
    /// 工作时长（秒），默认25分钟
    var workDuration: TimeInterval = 25 * 60
    
    /// 休息时长（秒），默认5分钟
    var breakDuration: TimeInterval = 5 * 60
    
    /// 是否启用触觉反馈
    var enableHapticFeedback: Bool = true
    
    /// 是否启用音频提醒
    var enableAudioAlerts: Bool = true
    
    /// 体态检查间隔（秒），默认每秒检查一次
    var postureCheckInterval: TimeInterval = 1.0
    
    /// 不良体态警告阈值（秒），默认10秒
    var badPostureWarningThreshold: TimeInterval = 10.0
    
    /// 是否启用摄像头检测
    var enableCameraDetection: Bool = true
    
    /// 默认设置
    static let `default` = AppSettings()
    
    /// 工作时长（分钟）
    var workDurationMinutes: Int {
        get { Int(workDuration / 60) }
        set { workDuration = TimeInterval(newValue * 60) }
    }
    
    /// 休息时长（分钟）
    var breakDurationMinutes: Int {
        get { Int(breakDuration / 60) }
        set { breakDuration = TimeInterval(newValue * 60) }
    }
}