//
//  WorkSessionViewModel.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation
import Combine
import SwiftUI
import AVFoundation

/// 主工作界面的ViewModel，协调番茄时钟和体态检测服务
@MainActor
class WorkSessionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var pomodoroService: any PomodoroServiceProtocol
    @Published var postureService: any PostureDetectionServiceProtocol
    @Published var showingStats = false
    @Published var showingSettings = false
    @Published var sessionState: SessionState = .idle
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // MARK: - Computed Properties
    var currentPosture: PostureType {
        postureService.currentPosture
    }
    
    var timeRemaining: TimeInterval {
        pomodoroService.timeRemaining
    }
    
    var isRunning: Bool {
        pomodoroService.isRunning
    }
    
    var isPaused: Bool {
        pomodoroService.isPaused
    }
    
    var isDetecting: Bool {
        postureService.isDetecting
    }
    
    var cameraPermissionStatus: AVAuthorizationStatus {
        postureService.cameraPermissionStatus
    }
    
    var completedSession: PomodoroSession? {
        pomodoroService.currentSession
    }
    
    var canStartSession: Bool {
        !isRunning && cameraPermissionStatus == .authorized
    }
    
    var canStartWithoutCamera: Bool {
        !isRunning
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var lastCompletedSessionId: UUID?
    let statisticsService: StatisticsServiceProtocol
    
    // MARK: - Session States
    enum SessionState: Equatable {
        case idle
        case running
        case paused
        case completed
        case error(String)
    }
    
    // MARK: - Initialization
    init() {
        self.pomodoroService = PomodoroService()
        self.postureService = PostureDetectionService()
        self.statisticsService = StatisticsService()
        
        setupBindings()
        setupPostureIntegration()
    }
    
    init(
        pomodoroService: any PomodoroServiceProtocol,
        postureService: any PostureDetectionServiceProtocol,
        statisticsService: StatisticsServiceProtocol
    ) {
        self.pomodoroService = pomodoroService
        self.postureService = postureService
        self.statisticsService = statisticsService
        
        setupBindings()
        setupPostureIntegration()
    }
    
    // MARK: - Setup Methods
    
    private func setupBindings() {
        // Monitor session state changes with a timer
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateSessionState()
            }
            .store(in: &cancellables)
    }
    
    private func setupPostureIntegration() {
        // Connect posture changes to pomodoro service
        postureService.postureChangePublisher
            .sink { [weak self] posture in
                self?.handlePostureChange(posture)
            }
            .store(in: &cancellables)
    }
    
    private func updateSessionState() {
        if pomodoroService.isRunning {
            sessionState = pomodoroService.isPaused ? .paused : .running
        } else if let session = pomodoroService.currentSession {
            sessionState = .completed
            // Handle session completion if it's a new completion
            if lastCompletedSessionId != session.id {
                lastCompletedSessionId = session.id
                handleSessionCompletion(session)
            }
        } else {
            sessionState = .idle
        }
    }
    
    // MARK: - Session Control Methods
    
    /// 开始新的工作会话
    func startWorkSession() {
        guard !isRunning else { return }
        
        // 清除之前的错误
        clearError()
        
        // 检查摄像头权限
        if cameraPermissionStatus == .authorized {
            startSessionWithPostureDetection()
        } else {
            startSessionWithoutPostureDetection()
        }
    }
    
    /// 暂停当前会话
    func pauseSession() {
        guard isRunning && !isPaused else { return }
        
        pomodoroService.pauseSession()
        postureService.stopDetection()
        
        sessionState = .paused
    }
    
    /// 恢复暂停的会话
    func resumeSession() {
        guard isRunning && isPaused else { return }
        
        pomodoroService.resumeSession()
        
        // 如果有摄像头权限，重新开始体态检测
        if cameraPermissionStatus == .authorized {
            postureService.startDetection()
        }
        
        sessionState = .running
    }
    
    /// 重置会话到初始状态
    func resetSession() {
        pomodoroService.resetSession()
        postureService.stopDetection()
        
        sessionState = .idle
        clearError()
    }
    
    /// 手动完成当前会话
    func completeSession() {
        guard isRunning else { return }
        
        pomodoroService.completeSession()
        postureService.stopDetection()
        
        sessionState = .completed
    }
    
    // MARK: - Camera Permission Methods
    
    /// 请求摄像头权限
    func requestCameraPermission() async {
        let granted = await postureService.requestCameraPermission()
        
        if granted {
            print("摄像头权限已获得")
        } else {
            showError("需要摄像头权限来检测体态。您可以在设置中启用摄像头权限，或选择仅使用计时器功能。")
        }
    }
    
    /// 检查是否支持体态检测
    func isPostureDetectionSupported() -> Bool {
        return postureService.isPostureDetectionSupported()
    }
    
    // MARK: - Navigation Methods
    
    /// 显示统计界面
    func showStatistics() {
        showingStats = true
    }
    
    /// 隐藏统计界面
    func hideStatistics() {
        showingStats = false
    }
    
    /// 显示设置界面
    func showSettings() {
        showingSettings = true
    }
    
    /// 隐藏设置界面
    func hideSettings() {
        showingSettings = false
    }
    
    // MARK: - Private Helper Methods
    
    private func startSessionWithPostureDetection() {
        pomodoroService.startSession()
        postureService.startDetection()
        
        sessionState = .running
        print("工作会话已开始（包含体态检测）")
    }
    
    private func startSessionWithoutPostureDetection() {
        pomodoroService.startSession()
        
        sessionState = .running
        print("工作会话已开始（仅计时器模式）")
    }
    
    private func handlePostureChange(_ posture: PostureType) {
        // 如果番茄时钟服务支持体态更新，则更新体态
        if let pomodoroService = pomodoroService as? PomodoroService {
            pomodoroService.updateCurrentPosture(posture)
        }
    }
    
    private func handleSessionCompletion(_ session: PomodoroSession) {
        // 保存会话到统计服务
        statisticsService.saveSession(session)
        
        sessionState = .completed
        
        // 自动显示统计界面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showStatistics()
        }
        
        print("会话已完成，健康分数: \(String(format: "%.1f", session.healthScore))%")
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        sessionState = .error(message)
    }
    
    private func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    // MARK: - Settings Management
    
    /// 更新应用设置
    func updateSettings(_ settings: AppSettings) {
        pomodoroService.settings = settings
        
        // 更新体态检测服务设置
        if let postureService = postureService as? PostureDetectionService {
            postureService.updateSettings(settings)
        }
    }
    
    /// 获取当前设置
    func getCurrentSettings() -> AppSettings {
        return pomodoroService.settings
    }
    
    // MARK: - Utility Methods
    
    /// 格式化时间显示
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 获取会话进度百分比
    func getSessionProgress() -> Double {
        let totalDuration = pomodoroService.settings.workDuration
        let elapsed = totalDuration - timeRemaining
        return elapsed / totalDuration
    }
    
    /// 获取当前不良体态持续时间
    func getCurrentBadPostureDuration() -> TimeInterval {
        return postureService.badPostureDuration
    }
    
    /// 检查是否需要显示体态警告
    func shouldShowPostureWarning() -> Bool {
        let threshold = pomodoroService.settings.badPostureWarningThreshold
        return getCurrentBadPostureDuration() >= threshold && !currentPosture.isHealthy
    }
}

// MARK: - Extensions for Convenience

extension WorkSessionViewModel {
    /// 会话状态的用户友好描述
    var sessionStateDescription: String {
        switch sessionState {
        case .idle:
            return "准备开始"
        case .running:
            return "工作中"
        case .paused:
            return "已暂停"
        case .completed:
            return "已完成"
        case .error(let message):
            return "错误: \(message)"
        }
    }
    
    /// 主要操作按钮的标题
    var primaryButtonTitle: String {
        switch sessionState {
        case .idle:
            return "开始工作"
        case .running:
            return "暂停"
        case .paused:
            return "继续"
        case .completed:
            return "开始新会话"
        case .error:
            return "重试"
        }
    }
    
    /// 是否显示重置按钮
    var showResetButton: Bool {
        return sessionState == .running || sessionState == .paused
    }
    
    /// 是否显示统计按钮
    var showStatsButton: Bool {
        return sessionState == .completed || completedSession != nil
    }
}