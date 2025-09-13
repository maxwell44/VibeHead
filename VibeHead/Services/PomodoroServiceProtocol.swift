//
//  PomodoroServiceProtocol.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation
import Combine

/// 番茄时钟服务协议，定义番茄工作法的核心功能
protocol PomodoroServiceProtocol: ObservableObject {
    /// 当前会话
    var currentSession: PomodoroSession? { get }
    
    /// 剩余时间
    var timeRemaining: TimeInterval { get }
    
    /// 是否正在运行
    var isRunning: Bool { get }
    
    /// 是否暂停
    var isPaused: Bool { get }
    
    /// 应用设置
    var settings: AppSettings { get set }
    
    /// 开始新会话
    func startSession()
    
    /// 暂停当前会话
    func pauseSession()
    
    /// 恢复会话
    func resumeSession()
    
    /// 重置会话
    func resetSession()
    
    /// 完成会话
    func completeSession()
    
    /// 添加体态记录到当前会话
    /// - Parameter record: 体态记录
    func addPostureRecord(_ record: PostureRecord)
    
    /// 更新设置
    /// - Parameter settings: 新的设置
    func updateSettings(_ settings: AppSettings)
}