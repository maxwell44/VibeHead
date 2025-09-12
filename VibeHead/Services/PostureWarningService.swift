//
//  PostureWarningService.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation
import Combine

/// 体态警告服务，监控不良体态持续时间并触发警告
class PostureWarningService: ObservableObject {
    // MARK: - Properties
    
    /// 当前不良体态开始时间
    private var badPostureStartTime: Date?
    
    /// 当前体态类型
    private var currentPosture: PostureType?
    
    /// 警告计时器
    private var warningTimer: Timer?
    
    /// 应用设置
    private var settings: AppSettings
    
    /// 警告回调
    private var onWarningTriggered: ((PostureType) -> Void)?
    
    // MARK: - Initialization
    
    init(settings: AppSettings) {
        self.settings = settings
    }
    
    deinit {
        stopWarningTimer()
    }
    
    // MARK: - Public Methods
    
    /// 设置警告回调
    /// - Parameter callback: 警告触发时的回调
    func setWarningCallback(_ callback: @escaping (PostureType) -> Void) {
        onWarningTriggered = callback
    }
    
    /// 更新体态状态
    /// - Parameter posture: 新的体态类型
    func updatePosture(_ posture: PostureType) {
        // 如果体态类型没有变化，不需要处理
        if currentPosture == posture {
            return
        }
        
        currentPosture = posture
        
        if posture.isHealthy {
            // 体态良好，停止警告计时器
            stopBadPostureTracking()
        } else {
            // 体态不良，开始跟踪
            startBadPostureTracking(posture)
        }
    }
    
    /// 停止体态监控
    func stopMonitoring() {
        stopBadPostureTracking()
        currentPosture = nil
    }
    
    /// 更新设置
    /// - Parameter newSettings: 新的应用设置
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
    }
    
    // MARK: - Private Methods
    
    /// 开始跟踪不良体态
    /// - Parameter posture: 不良体态类型
    private func startBadPostureTracking(_ posture: PostureType) {
        stopWarningTimer()
        
        badPostureStartTime = Date()
        
        // 设置警告计时器
        warningTimer = Timer.scheduledTimer(withTimeInterval: settings.badPostureWarningThreshold, repeats: false) { [weak self] _ in
            self?.triggerWarning(for: posture)
        }
    }
    
    /// 停止不良体态跟踪
    private func stopBadPostureTracking() {
        stopWarningTimer()
        badPostureStartTime = nil
    }
    
    /// 停止警告计时器
    private func stopWarningTimer() {
        warningTimer?.invalidate()
        warningTimer = nil
    }
    
    /// 触发警告
    /// - Parameter posture: 触发警告的体态类型
    private func triggerWarning(for posture: PostureType) {
        guard !posture.isHealthy else { return }
        
        onWarningTriggered?(posture)
        
        // 重新设置计时器，持续警告
        warningTimer = Timer.scheduledTimer(withTimeInterval: settings.badPostureWarningThreshold, repeats: false) { [weak self] _ in
            self?.triggerWarning(for: posture)
        }
    }
}

// MARK: - Convenience Extension
extension PostureWarningService {
    /// 获取当前不良体态持续时间
    var currentBadPostureDuration: TimeInterval {
        guard let startTime = badPostureStartTime,
              let posture = currentPosture,
              !posture.isHealthy else {
            return 0
        }
        
        return Date().timeIntervalSince(startTime)
    }
    
    /// 是否正在跟踪不良体态
    var isTrackingBadPosture: Bool {
        return badPostureStartTime != nil && currentPosture?.isHealthy == false
    }
}