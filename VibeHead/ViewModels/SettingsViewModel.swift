//
//  SettingsViewModel.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import Foundation
import Combine

/// 设置界面ViewModel，管理设置界面的状态和交互
class SettingsViewModel: ObservableObject {
    @Published var settingsService: any SettingsServiceProtocol
    @Published var showingResetAlert = false
    @Published var showingDataClearAlert = false
    
    private var cancellables = Set<AnyCancellable>()
    private let statisticsService: any StatisticsServiceProtocol
    var onSettingsChanged: ((AppSettings) -> Void)?
    
    /// 初始化设置ViewModel
    /// - Parameters:
    ///   - settingsService: 设置服务
    ///   - statisticsService: 统计服务（用于数据清除）
    ///   - onSettingsChanged: 设置变更回调
    init(
        settingsService: any SettingsServiceProtocol = SettingsService(),
        statisticsService: any StatisticsServiceProtocol = StatisticsService(),
        onSettingsChanged: ((AppSettings) -> Void)? = nil
    ) {
        self.settingsService = settingsService
        self.statisticsService = statisticsService
        self.onSettingsChanged = onSettingsChanged
        
        // 监听设置变化 - 使用定时器来检测变化
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                if let settings = self?.settingsService.settings {
                    self?.onSettingsChanged?(settings)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 设置更新方法
    
    /// 更新工作时长
    /// - Parameter minutes: 工作时长（分钟）
    func updateWorkDuration(_ minutes: Double) {
        let roundedMinutes = Int(minutes.rounded())
        settingsService.settings.workDurationMinutes = roundedMinutes
        settingsService.saveSettings()
    }
    
    /// 更新休息时长
    /// - Parameter minutes: 休息时长（分钟）
    func updateBreakDuration(_ minutes: Double) {
        let roundedMinutes = Int(minutes.rounded())
        settingsService.settings.breakDurationMinutes = roundedMinutes
        settingsService.saveSettings()
    }
    
    /// 切换触觉反馈
    func toggleHapticFeedback() {
        settingsService.settings.enableHapticFeedback.toggle()
        settingsService.saveSettings()
    }
    
    /// 切换音频提醒
    func toggleAudioAlerts() {
        settingsService.settings.enableAudioAlerts.toggle()
        settingsService.saveSettings()
    }
    
    /// 切换摄像头检测
    func toggleCameraDetection() {
        settingsService.settings.enableCameraDetection.toggle()
        settingsService.saveSettings()
    }
    
    // MARK: - 数据管理方法
    
    /// 显示重置设置确认对话框
    func showResetAlert() {
        showingResetAlert = true
    }
    
    /// 重置设置到默认值
    func resetSettings() {
        settingsService.resetToDefaults()
        showingResetAlert = false
    }
    
    /// 显示清除数据确认对话框
    func showDataClearAlert() {
        showingDataClearAlert = true
    }
    
    /// 清除所有用户数据
    func clearAllData() {
        statisticsService.clearAllData()
        settingsService.resetToDefaults()
        showingDataClearAlert = false
    }
    
    // MARK: - 计算属性
    
    /// 工作时长范围（5-60分钟）
    var workDurationRange: ClosedRange<Double> {
        5...60
    }
    
    /// 休息时长范围（1-30分钟）
    var breakDurationRange: ClosedRange<Double> {
        1...30
    }
    
    /// 当前工作时长（分钟）
    var currentWorkDuration: Double {
        Double(settingsService.settings.workDurationMinutes)
    }
    
    /// 当前休息时长（分钟）
    var currentBreakDuration: Double {
        Double(settingsService.settings.breakDurationMinutes)
    }
    
    /// 格式化时长显示
    /// - Parameter minutes: 分钟数
    /// - Returns: 格式化的时长字符串
    func formatDuration(_ minutes: Double) -> String {
        let roundedMinutes = Int(minutes.rounded())
        return "\(roundedMinutes) 分钟"
    }
}