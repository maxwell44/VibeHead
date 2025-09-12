//
//  StatisticsServiceProtocol.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation

/// 健康趋势数据
struct HealthTrends: Codable {
    let averageHealthScore: Double
    let totalSessions: Int
    let totalWorkTime: TimeInterval
    let improvementTrend: Double // 正数表示改善，负数表示恶化
    let bestSession: PomodoroSession?
    let recentSessions: [PomodoroSession]
}

/// 统计服务协议，定义数据统计和持久化功能
protocol StatisticsServiceProtocol {
    /// 保存会话数据
    /// - Parameter session: 要保存的会话
    func saveSession(_ session: PomodoroSession)
    
    /// 获取会话历史记录
    /// - Returns: 历史会话列表
    func getSessionHistory() -> [PomodoroSession]
    
    /// 获取最近N天的会话
    /// - Parameter days: 天数
    /// - Returns: 会话列表
    func getRecentSessions(days: Int) -> [PomodoroSession]
    
    /// 计算健康趋势
    /// - Returns: 健康趋势数据
    func calculateHealthTrends() -> HealthTrends
    
    /// 清除所有数据
    func clearAllData()
    
    /// 清除过期数据（超过30天）
    func clearExpiredData()
    
    /// 获取应用设置
    /// - Returns: 当前设置
    func getAppSettings() -> AppSettings
    
    /// 保存应用设置
    /// - Parameter settings: 要保存的设置
    func saveAppSettings(_ settings: AppSettings)
}