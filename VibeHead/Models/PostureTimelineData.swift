//
//  PostureTimelineData.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import Foundation

/// 体态时间轴数据模型，用于Swift Charts显示
struct PostureTimelineData: Identifiable {
    let id = UUID()
    let posture: PostureType
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    
    /// 从PostureRecord创建时间轴数据
    /// - Parameter record: 体态记录
    init(from record: PostureRecord) {
        self.posture = record.posture
        self.startTime = record.startTime
        self.endTime = record.endTime
        self.duration = record.duration
    }
    
    /// 直接创建时间轴数据
    /// - Parameters:
    ///   - posture: 体态类型
    ///   - startTime: 开始时间
    ///   - endTime: 结束时间
    init(posture: PostureType, startTime: Date, endTime: Date) {
        self.posture = posture
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
    }
}

/// 会话时间轴数据，包含完整会话的时间轴信息
struct SessionTimelineData {
    let sessionId: UUID
    let sessionStartTime: Date
    let sessionEndTime: Date
    let postureTimeline: [PostureTimelineData]
    
    /// 从PomodoroSession创建会话时间轴数据
    /// - Parameter session: 番茄工作会话
    init(from session: PomodoroSession) {
        self.sessionId = session.id
        self.sessionStartTime = session.startTime
        self.sessionEndTime = session.endTime
        self.postureTimeline = session.postureData.map { PostureTimelineData(from: $0) }
    }
    
    /// 获取指定时间范围内的体态数据
    /// - Parameters:
    ///   - startTime: 开始时间
    ///   - endTime: 结束时间
    /// - Returns: 过滤后的体态时间轴数据
    func postureData(from startTime: Date, to endTime: Date) -> [PostureTimelineData] {
        return postureTimeline.filter { data in
            data.startTime >= startTime && data.endTime <= endTime
        }
    }
    
    /// 获取会话总时长
    var totalDuration: TimeInterval {
        return sessionEndTime.timeIntervalSince(sessionStartTime)
    }
}