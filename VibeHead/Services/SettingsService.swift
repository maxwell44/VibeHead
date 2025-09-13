//
//  SettingsService.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import Foundation
import Combine

/// 设置服务协议，定义设置管理接口
protocol SettingsServiceProtocol: ObservableObject {
    var settings: AppSettings { get set }
    
    func loadSettings()
    func saveSettings()
    func resetToDefaults()
}

/// 设置服务实现，负责应用设置的持久化管理
class SettingsService: SettingsServiceProtocol {
    @Published var settings: AppSettings = .default
    
    private let dataRepository: LocalDataRepository
    
    /// 初始化设置服务
    /// - Parameter dataRepository: 数据仓库实例，默认为新实例
    init(dataRepository: LocalDataRepository = LocalDataRepository()) {
        self.dataRepository = dataRepository
        loadSettings()
    }
    
    /// 从数据仓库加载设置
    func loadSettings() {
        settings = dataRepository.getAppSettings()
    }
    
    /// 保存设置到数据仓库
    func saveSettings() {
        dataRepository.saveAppSettings(settings)
    }
    
    /// 重置为默认设置
    func resetToDefaults() {
        settings = .default
        saveSettings()
    }
}

// MARK: - 便利方法
extension SettingsService {
    /// 更新工作时长（分钟）
    /// - Parameter minutes: 工作时长（分钟）
    func updateWorkDuration(minutes: Int) {
        settings.workDurationMinutes = minutes
        saveSettings()
    }
    
    /// 更新休息时长（分钟）
    /// - Parameter minutes: 休息时长（分钟）
    func updateBreakDuration(minutes: Int) {
        settings.breakDurationMinutes = minutes
        saveSettings()
    }
    
    /// 切换触觉反馈设置
    func toggleHapticFeedback() {
        settings.enableHapticFeedback.toggle()
        saveSettings()
    }
    
    /// 切换音频提醒设置
    func toggleAudioAlerts() {
        settings.enableAudioAlerts.toggle()
        saveSettings()
    }
    
    /// 切换摄像头检测设置
    func toggleCameraDetection() {
        settings.enableCameraDetection.toggle()
        saveSettings()
    }
    
    /// 更新体态检查间隔
    /// - Parameter interval: 检查间隔（秒）
    func updatePostureCheckInterval(_ interval: TimeInterval) {
        settings.postureCheckInterval = interval
        saveSettings()
    }
    
    /// 更新不良体态警告阈值
    /// - Parameter threshold: 警告阈值（秒）
    func updateBadPostureWarningThreshold(_ threshold: TimeInterval) {
        settings.badPostureWarningThreshold = threshold
        saveSettings()
    }
}