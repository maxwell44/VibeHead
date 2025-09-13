//
//  LocalDataRepository.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation
import Combine

/// 本地数据仓库实现，使用UserDefaults进行数据持久化
class LocalDataRepository: StatisticsServiceProtocol, ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// 数据保留天数
    private let dataRetentionDays = 30
    
    init() {
        // 设置日期编码策略
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        // 首次启动时清理过期数据
        if !userDefaults.bool(forKey: UserDefaultsKeys.isFirstLaunch) {
            userDefaults.set(true, forKey: UserDefaultsKeys.isFirstLaunch)
        }
        
        // 延迟清理过期数据到后台队列，避免阻塞启动
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.clearExpiredData()
        }
    }
    
    // MARK: - Session Management
    
    func saveSession(_ session: PomodoroSession) {
        var history = getSessionHistory()
        history.append(session)
        
        // 按时间排序
        history.sort { $0.startTime < $1.startTime }
        
        // 清理过期数据
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(dataRetentionDays * 24 * 60 * 60))
        history = history.filter { $0.startTime > cutoffDate }
        
        // 保存到UserDefaults
        if let data = try? encoder.encode(history) {
            userDefaults.set(data, forKey: UserDefaultsKeys.sessionHistory)
            userDefaults.set(Date(), forKey: UserDefaultsKeys.lastSessionDate)
        }
    }
    
    func getSessionHistory() -> [PomodoroSession] {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.sessionHistory),
              let sessions = try? decoder.decode([PomodoroSession].self, from: data) else {
            return []
        }
        return sessions
    }
    
    func getRecentSessions(days: Int) -> [PomodoroSession] {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        return getSessionHistory().filter { $0.startTime > cutoffDate }
    }
    
    // MARK: - Statistics Calculation
    
    func calculateHealthTrends() -> HealthTrends {
        let allSessions = getSessionHistory()
        let recentSessions = getRecentSessions(days: 7) // 最近7天
        
        guard !allSessions.isEmpty else {
            return HealthTrends(
                averageHealthScore: 0,
                totalSessions: 0,
                totalWorkTime: 0,
                improvementTrend: 0,
                bestSession: nil,
                recentSessions: []
            )
        }
        
        // 计算平均健康分数
        let averageHealthScore = allSessions.reduce(0) { $0 + $1.healthScore } / Double(allSessions.count)
        
        // 计算总工作时间
        let totalWorkTime = allSessions.reduce(0) { $0 + $1.duration }
        
        // 找到最佳会话
        let bestSession = allSessions.max { $0.healthScore < $1.healthScore }
        
        // 计算改善趋势（比较最近7天与之前7天的平均分数）
        let improvementTrend = calculateImprovementTrend(sessions: allSessions)
        
        return HealthTrends(
            averageHealthScore: averageHealthScore,
            totalSessions: allSessions.count,
            totalWorkTime: totalWorkTime,
            improvementTrend: improvementTrend,
            bestSession: bestSession,
            recentSessions: recentSessions
        )
    }
    
    private func calculateImprovementTrend(sessions: [PomodoroSession]) -> Double {
        let now = Date()
        let sevenDaysAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
        let fourteenDaysAgo = now.addingTimeInterval(-14 * 24 * 60 * 60)
        
        let recentSessions = sessions.filter { $0.startTime > sevenDaysAgo }
        let previousSessions = sessions.filter { $0.startTime > fourteenDaysAgo && $0.startTime <= sevenDaysAgo }
        
        guard !recentSessions.isEmpty && !previousSessions.isEmpty else { return 0 }
        
        let recentAverage = recentSessions.reduce(0) { $0 + $1.healthScore } / Double(recentSessions.count)
        let previousAverage = previousSessions.reduce(0) { $0 + $1.healthScore } / Double(previousSessions.count)
        
        return recentAverage - previousAverage
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        userDefaults.removeObject(forKey: UserDefaultsKeys.sessionHistory)
        userDefaults.removeObject(forKey: UserDefaultsKeys.lastSessionDate)
        userDefaults.removeObject(forKey: UserDefaultsKeys.appSettings)
    }
    
    func clearExpiredData() {
        let sessions = getSessionHistory()
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(dataRetentionDays * 24 * 60 * 60))
        let validSessions = sessions.filter { $0.startTime > cutoffDate }
        
        if validSessions.count != sessions.count {
            if let data = try? encoder.encode(validSessions) {
                userDefaults.set(data, forKey: UserDefaultsKeys.sessionHistory)
            }
        }
    }
    
    // MARK: - Settings Management
    
    func getAppSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.appSettings),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return AppSettings.default
        }
        return settings
    }
    
    func saveAppSettings(_ settings: AppSettings) {
        if let data = try? encoder.encode(settings) {
            userDefaults.set(data, forKey: UserDefaultsKeys.appSettings)
        }
    }
}