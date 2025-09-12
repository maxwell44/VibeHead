//
//  PomodoroSession.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation

/// 番茄工作会话模型，包含完整的工作会话数据
struct PomodoroSession: Codable, Identifiable {
    let id = UUID()
    let startTime: Date
    let duration: TimeInterval
    let postureData: [PostureRecord]
    
    /// 会话结束时间
    var endTime: Date {
        return startTime.addingTimeInterval(duration)
    }
    
    /// 计算健康分数（优秀体态时间占总时间的百分比）
    var healthScore: Double {
        let excellentTime = postureData
            .filter { $0.posture == .excellent }
            .reduce(0) { $0 + $1.duration }
        
        guard duration > 0 else { return 0 }
        return (excellentTime / duration) * 100
    }
    
    /// 获取各种体态的时间分布
    var postureBreakdown: [PostureType: TimeInterval] {
        var breakdown: [PostureType: TimeInterval] = [:]
        
        for postureType in PostureType.allCases {
            let totalTime = postureData
                .filter { $0.posture == postureType }
                .reduce(0) { $0 + $1.duration }
            breakdown[postureType] = totalTime
        }
        
        return breakdown
    }
    
    /// 获取健康体态时间百分比
    var healthyPosturePercentage: Double {
        let healthyTime = postureData
            .filter { $0.posture.isHealthy }
            .reduce(0) { $0 + $1.duration }
        
        guard duration > 0 else { return 0 }
        return (healthyTime / duration) * 100
    }
    
    /// 创建新的番茄工作会话
    /// - Parameters:
    ///   - startTime: 开始时间
    ///   - duration: 会话持续时间
    ///   - postureData: 体态记录数据
    init(startTime: Date, duration: TimeInterval, postureData: [PostureRecord] = []) {
        self.startTime = startTime
        self.duration = duration
        self.postureData = postureData
    }
}