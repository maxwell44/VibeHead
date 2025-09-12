//
//  PostureRecord.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation

/// 体态记录模型，记录特定时间段内的体态状态
struct PostureRecord: Codable, Identifiable {
    let id = UUID()
    let posture: PostureType
    let startTime: Date
    let duration: TimeInterval
    
    /// 结束时间
    var endTime: Date {
        return startTime.addingTimeInterval(duration)
    }
    
    /// 创建新的体态记录
    /// - Parameters:
    ///   - posture: 体态类型
    ///   - startTime: 开始时间
    ///   - duration: 持续时间（秒）
    init(posture: PostureType, startTime: Date, duration: TimeInterval) {
        self.posture = posture
        self.startTime = startTime
        self.duration = duration
    }
}