//
//  PomodoroService.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation
import Combine

/// 番茄时钟服务实现，管理番茄工作法的核心逻辑
class PomodoroService: PomodoroServiceProtocol {
    // MARK: - Published Properties
    @Published var currentSession: PomodoroSession?
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var settings: AppSettings = .default
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var sessionStartTime: Date?
    private var pausedTime: TimeInterval = 0
    private var currentPostureRecords: [PostureRecord] = []
    private var currentPostureStartTime: Date?
    private var currentPostureType: PostureType?
    private let feedbackService = FeedbackService()
    private var postureWarningService: PostureWarningService?
    
    // MARK: - Initialization
    init() {
        loadSettings()
        resetTimer()
        setupPostureWarningService()
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Public Methods
    
    /// 开始新的番茄工作会话
    func startSession() {
        guard !isRunning else { return }
        
        // 如果是暂停状态，恢复会话
        if isPaused {
            resumeSession()
            return
        }
        
        // 开始新会话
        sessionStartTime = Date()
        timeRemaining = settings.workDuration
        currentPostureRecords = []
        pausedTime = 0
        
        isRunning = true
        isPaused = false
        
        // 播放开始反馈
        feedbackService.playFeedback(type: .sessionStart, settings: settings)
        
        startTimer()
    }
    
    /// 暂停当前会话
    func pauseSession() {
        guard isRunning && !isPaused else { return }
        
        isPaused = true
        stopTimer()
        
        // 停止体态警告监控
        postureWarningService?.stopMonitoring()
        
        // 记录当前体态（如果有的话）
        finishCurrentPostureRecord()
    }
    
    /// 恢复暂停的会话
    func resumeSession() {
        guard isRunning && isPaused else { return }
        
        isPaused = false
        startTimer()
    }
    
    /// 重置会话到初始状态
    func resetSession() {
        stopTimer()
        
        // 停止体态警告监控
        postureWarningService?.stopMonitoring()
        
        isRunning = false
        isPaused = false
        timeRemaining = settings.workDuration
        sessionStartTime = nil
        pausedTime = 0
        currentPostureRecords = []
        currentPostureStartTime = nil
        currentPostureType = nil
        currentSession = nil
    }
    
    /// 完成当前会话
    func completeSession() {
        guard let startTime = sessionStartTime else { return }
        
        stopTimer()
        
        // 停止体态警告监控
        postureWarningService?.stopMonitoring()
        
        // 完成当前体态记录
        finishCurrentPostureRecord()
        
        // 计算实际会话时长
        let actualDuration = settings.workDuration - timeRemaining
        
        // 播放完成反馈
        feedbackService.playFeedback(type: .sessionComplete, settings: settings)
        
        // 创建完成的会话
        currentSession = PomodoroSession(
            startTime: startTime,
            duration: actualDuration,
            postureData: currentPostureRecords
        )
        
        // 重置状态
        isRunning = false
        isPaused = false
        timeRemaining = 0
        sessionStartTime = nil
        pausedTime = 0
        currentPostureRecords = []
        currentPostureStartTime = nil
        currentPostureType = nil
    }
    
    /// 添加体态记录到当前会话
    /// - Parameter record: 体态记录
    func addPostureRecord(_ record: PostureRecord) {
        guard isRunning && !isPaused else { return }
        currentPostureRecords.append(record)
    }
    
    // MARK: - Private Methods
    
    /// 开始计时器
    private func startTimer() {
        stopTimer() // 确保没有重复的计时器
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    /// 停止计时器
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 更新计时器
    private func updateTimer() {
        guard timeRemaining > 0 else {
            // 时间到了，完成会话
            completeSession()
            return
        }
        
        timeRemaining -= 1
    }
    
    /// 重置计时器到默认时间
    private func resetTimer() {
        timeRemaining = settings.workDuration
    }
    
    /// 完成当前体态记录
    private func finishCurrentPostureRecord() {
        guard let startTime = currentPostureStartTime,
              let postureType = currentPostureType else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        if duration > 0 {
            let record = PostureRecord(
                posture: postureType,
                startTime: startTime,
                duration: duration
            )
            currentPostureRecords.append(record)
        }
        
        currentPostureStartTime = nil
        currentPostureType = nil
    }
    
    /// 加载设置
    private func loadSettings() {
        // 从数据仓库加载设置
        let repository = LocalDataRepository()
        settings = repository.getAppSettings()
        resetTimer()
    }
    
    /// 更新设置
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        resetTimer()
        setupPostureWarningService()
        
        // 保存设置到数据仓库
        let repository = LocalDataRepository()
        repository.saveAppSettings(settings)
    }
    
    /// 设置体态警告服务
    private func setupPostureWarningService() {
        postureWarningService = PostureWarningService(settings: settings)
        postureWarningService?.setWarningCallback { [weak self] postureType in
            self?.triggerPostureWarning(for: postureType)
        }
    }
}

// MARK: - Posture Tracking Extension
extension PomodoroService {
    /// 更新当前体态状态
    /// - Parameter posture: 新的体态类型
    func updateCurrentPosture(_ posture: PostureType) {
        guard isRunning && !isPaused else { return }
        
        // 如果体态类型没有变化，不需要处理
        if currentPostureType == posture {
            return
        }
        
        // 完成之前的体态记录
        finishCurrentPostureRecord()
        
        // 开始新的体态记录
        currentPostureType = posture
        currentPostureStartTime = Date()
        
        // 更新体态警告服务
        postureWarningService?.updatePosture(posture)
    }
    
    /// 触发体态警告反馈
    /// - Parameter postureType: 触发警告的体态类型
    func triggerPostureWarning(for postureType: PostureType) {
        guard isRunning && !isPaused && !postureType.isHealthy else { return }
        
        // 播放警告反馈
        feedbackService.playFeedback(type: .postureWarning, settings: settings)
    }
}