//
//  UserDefaultsKeys.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation

/// UserDefaults键值定义，统一管理本地存储键名
enum UserDefaultsKeys {
    /// 应用设置
    static let appSettings = "healthy_code_app_settings"
    
    /// 会话历史记录
    static let sessionHistory = "healthy_code_session_history"
    
    /// 最后会话日期
    static let lastSessionDate = "healthy_code_last_session_date"
    
    /// 首次启动标记
    static let isFirstLaunch = "healthy_code_is_first_launch"
    
    /// 摄像头权限请求次数
    static let cameraPermissionRequestCount = "healthy_code_camera_permission_count"
    
    /// 数据版本（用于数据迁移）
    static let dataVersion = "healthy_code_data_version"
}