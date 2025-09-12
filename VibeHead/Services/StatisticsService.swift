//
//  StatisticsService.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation
import Combine

/// 统计服务实现，负责计算健康分数和体态分析
class StatisticsService: StatisticsServiceProtocol, ObservableObject {
    private let dataRepository: LocalDataRepository
    
    init(dataRepository: LocalDataRepository = LocalDataRepository()) {
        self.dataRepository = dataRepository
    }
    
    // MARK: - Session Management
    
    func saveSession(_ session: PomodoroSession) {
        dataRepository.saveSession(session)
    }
    
    func getSessionHistory() -> [PomodoroSession] {
        return dataRepository.getSessionHistory()
    }
    
    func getRecentSessions(days: Int) -> [PomodoroSession] {
        return dataRepository.getRecentSessions(days: days)
    }
    
    // MARK: - Statistics Calculation
    
    func calculateHealthTrends() -> HealthTrends {
        return dataRepository.calculateHealthTrends()
    }
    
    /// 计算单个会话的详细统计信息
    func calculateSessionStatistics(_ session: PomodoroSession) -> SessionStatistics {
        let totalDuration = session.duration
        
        // 计算每种体态的时间
        var postureTimeBreakdown: [PostureType: TimeInterval] = [:]
        for postureType in PostureType.allCases {
            postureTimeBreakdown[postureType] = 0
        }
        
        // 累计每种体态的时间
        for record in session.postureData {
            postureTimeBreakdown[record.posture, default: 0] += record.duration
        }
        
        // 计算百分比
        var posturePercentages: [PostureType: Double] = [:]
        for postureType in PostureType.allCases {
            let time = postureTimeBreakdown[postureType] ?? 0
            posturePercentages[postureType] = totalDuration > 0 ? (time / totalDuration) * 100 : 0
        }
        
        // 计算健康分数
        let excellentTime = postureTimeBreakdown[.excellent] ?? 0
        let healthScore = totalDuration > 0 ? (excellentTime / totalDuration) * 100 : 0
        
        // 计算体态变化次数
        let postureChanges = calculatePostureChanges(session.postureData)
        
        // 计算最长连续优秀体态时间
        let longestExcellentStreak = calculateLongestExcellentStreak(session.postureData)
        
        return SessionStatistics(
            session: session,
            healthScore: healthScore,
            postureTimeBreakdown: postureTimeBreakdown,
            posturePercentages: posturePercentages,
            postureChanges: postureChanges,
            longestExcellentStreak: longestExcellentStreak
        )
    }
    
    /// 计算多个会话的聚合统计信息
    func calculateAggregateStatistics(sessions: [PomodoroSession]) -> AggregateStatistics {
        guard !sessions.isEmpty else {
            return AggregateStatistics.empty
        }
        
        let totalSessions = sessions.count
        let totalWorkTime = sessions.reduce(0) { $0 + $1.duration }
        
        // 计算平均健康分数
        let averageHealthScore = sessions.reduce(0) { $0 + $1.healthScore } / Double(totalSessions)
        
        // 计算总体体态时间分解
        var totalPostureTime: [PostureType: TimeInterval] = [:]
        for postureType in PostureType.allCases {
            totalPostureTime[postureType] = 0
        }
        
        for session in sessions {
            for record in session.postureData {
                totalPostureTime[record.posture, default: 0] += record.duration
            }
        }
        
        // 计算总体体态百分比
        var overallPosturePercentages: [PostureType: Double] = [:]
        for postureType in PostureType.allCases {
            let time = totalPostureTime[postureType] ?? 0
            overallPosturePercentages[postureType] = totalWorkTime > 0 ? (time / totalWorkTime) * 100 : 0
        }
        
        // 找到最佳和最差会话
        let bestSession = sessions.max { $0.healthScore < $1.healthScore }
        let worstSession = sessions.min { $0.healthScore < $1.healthScore }
        
        // 计算改善趋势
        let improvementTrend = calculateImprovementTrend(sessions: sessions)
        
        return AggregateStatistics(
            totalSessions: totalSessions,
            totalWorkTime: totalWorkTime,
            averageHealthScore: averageHealthScore,
            overallPosturePercentages: overallPosturePercentages,
            bestSession: bestSession,
            worstSession: worstSession,
            improvementTrend: improvementTrend
        )
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        dataRepository.clearAllData()
    }
    
    func clearExpiredData() {
        dataRepository.clearExpiredData()
    }
    
    // MARK: - Settings Management
    
    func getAppSettings() -> AppSettings {
        return dataRepository.getAppSettings()
    }
    
    func saveAppSettings(_ settings: AppSettings) {
        dataRepository.saveAppSettings(settings)
    }
    
    // MARK: - Private Helper Methods
    
    /// 计算体态变化次数
    private func calculatePostureChanges(_ postureData: [PostureRecord]) -> Int {
        guard postureData.count > 1 else { return 0 }
        
        var changes = 0
        for i in 1..<postureData.count {
            if postureData[i].posture != postureData[i-1].posture {
                changes += 1
            }
        }
        return changes
    }
    
    /// 计算最长连续优秀体态时间
    private func calculateLongestExcellentStreak(_ postureData: [PostureRecord]) -> TimeInterval {
        var longestStreak: TimeInterval = 0
        var currentStreak: TimeInterval = 0
        
        for record in postureData {
            if record.posture == .excellent {
                currentStreak += record.duration
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return longestStreak
    }
    
    /// 计算改善趋势（比较最近一半会话与前一半会话的平均分数）
    private func calculateImprovementTrend(sessions: [PomodoroSession]) -> Double {
        guard sessions.count >= 4 else { return 0 }
        
        let sortedSessions = sessions.sorted { $0.startTime < $1.startTime }
        let midPoint = sortedSessions.count / 2
        
        let earlierSessions = Array(sortedSessions[0..<midPoint])
        let laterSessions = Array(sortedSessions[midPoint..<sortedSessions.count])
        
        let earlierAverage = earlierSessions.reduce(0) { $0 + $1.healthScore } / Double(earlierSessions.count)
        let laterAverage = laterSessions.reduce(0) { $0 + $1.healthScore } / Double(laterSessions.count)
        
        return laterAverage - earlierAverage
    }
}

// MARK: - Supporting Data Models

/// 单个会话的详细统计信息
struct SessionStatistics {
    let session: PomodoroSession
    let healthScore: Double
    let postureTimeBreakdown: [PostureType: TimeInterval]
    let posturePercentages: [PostureType: Double]
    let postureChanges: Int
    let longestExcellentStreak: TimeInterval
    
    /// 获取格式化的健康分数文本
    var formattedHealthScore: String {
        return String(format: "%.1f%%", healthScore)
    }
    
    /// 获取健康分数对应的颜色
    var healthScoreColor: PostureType {
        switch healthScore {
        case 80...100:
            return .excellent
        case 60..<80:
            return .tilted // 使用橙色表示中等
        default:
            return .lookingDown // 使用红色表示需要改善
        }
    }
    
    /// 获取格式化的最长优秀体态时间
    var formattedLongestStreak: String {
        let minutes = Int(longestExcellentStreak / 60)
        let seconds = Int(longestExcellentStreak.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// 多个会话的聚合统计信息
struct AggregateStatistics {
    let totalSessions: Int
    let totalWorkTime: TimeInterval
    let averageHealthScore: Double
    let overallPosturePercentages: [PostureType: Double]
    let bestSession: PomodoroSession?
    let worstSession: PomodoroSession?
    let improvementTrend: Double
    
    /// 空的聚合统计信息
    static let empty = AggregateStatistics(
        totalSessions: 0,
        totalWorkTime: 0,
        averageHealthScore: 0,
        overallPosturePercentages: [:],
        bestSession: nil,
        worstSession: nil,
        improvementTrend: 0
    )
    
    /// 获取格式化的总工作时间
    var formattedTotalWorkTime: String {
        let hours = Int(totalWorkTime / 3600)
        let minutes = Int((totalWorkTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return String(format: "%d小时%d分钟", hours, minutes)
        } else {
            return String(format: "%d分钟", minutes)
        }
    }
    
    /// 获取格式化的平均健康分数
    var formattedAverageHealthScore: String {
        return String(format: "%.1f%%", averageHealthScore)
    }
    
    /// 获取改善趋势的描述
    var improvementTrendDescription: String {
        switch improvementTrend {
        case 10...:
            return "显著改善"
        case 5..<10:
            return "持续改善"
        case 1..<5:
            return "轻微改善"
        case -1...1:
            return "保持稳定"
        case -5..<(-1):
            return "轻微下降"
        case -10..<(-5):
            return "持续下降"
        default:
            return "显著下降"
        }
    }
}