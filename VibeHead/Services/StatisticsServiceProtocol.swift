//
//  StatisticsServiceProtocol.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation

/// 健康趋势数据模型
struct HealthTrends {
    /// 平均健康分数
    let averageHealthScore: Double
    
    /// 总会话数
    let totalSessions: Int
    
    /// 总工作时间（秒）
    let totalWorkTime: TimeInterval
    
    /// 改善趋势（正数表示改善，负数表示退步）
    let improvementTrend: Double
    
    /// 最佳会话
    let bestSession: PomodoroSession?
    
    /// 最近会话列表
    let recentSessions: [PomodoroSession]
}

/// 统计服务协议，定义数据统计和持久化的核心功能
protocol StatisticsServiceProtocol {
    // MARK: - Session Management
    
    /// 保存番茄工作会话
    /// - Parameter session: 要保存的会话数据
    func saveSession(_ session: PomodoroSession)
    
    /// 获取所有会话历史记录
    /// - Returns: 会话历史数组，按时间排序
    func getSessionHistory() -> [PomodoroSession]
    
    /// 获取最近指定天数的会话记录
    /// - Parameter days: 天数
    /// - Returns: 最近会话数组
    func getRecentSessions(days: Int) -> [PomodoroSession]
    
    // MARK: - Statistics Calculation
    
    /// 计算健康趋势数据
    /// - Returns: 包含各种统计指标的健康趋势数据
    func calculateHealthTrends() -> HealthTrends
    
    // MARK: - Data Management
    
    /// 清除所有数据
    func clearAllData()
    
    /// 清除过期数据（超过30天的数据）
    func clearExpiredData()
    
    // MARK: - Settings Management
    
    /// 获取应用设置
    /// - Returns: 当前应用设置
    func getAppSettings() -> AppSettings
    
    /// 保存应用设置
    /// - Parameter settings: 要保存的设置
    func saveAppSettings(_ settings: AppSettings)
}