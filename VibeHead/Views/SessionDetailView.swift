//
//  SessionDetailView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI

/// 会话详情视图，显示单个会话的详细统计信息
struct SessionDetailView: View {
    let session: PomodoroSession
    let statisticsService: StatisticsService
    @Environment(\.dismiss) private var dismiss
    @State private var sessionStats: SessionStatistics?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let stats = sessionStats {
                        // 会话基本信息
                        SessionInfoCard(session: session, stats: stats)
                        
                        // 体态时间分解
                        PostureBreakdownCard(stats: stats)
                        
                        // 体态时间轴图表
                        PostureTimelineCard(session: session)
                        
                        // 体态百分比进度条
                        PosturePercentageCard(stats: stats)
                        
                        // 其他统计信息
                        AdditionalStatsCard(stats: stats)
                    } else {
                        ProgressView("加载中...")
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("会话详情")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareButton(session: session)
                }
            }
        }
        .onAppear {
            loadSessionStatistics()
        }
    }
    
    private func loadSessionStatistics() {
        sessionStats = statisticsService.calculateSessionStatistics(session)
    }
}

/// 会话基本信息卡片
struct SessionInfoCard: View {
    let session: PomodoroSession
    let stats: SessionStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("会话概览")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // 健康分数大显示
            HealthScoreDisplay(
                score: stats.healthScore,
                title: "健康分数"
            )
            
            // 会话信息
            HStack(spacing: 20) {
                InfoItem(
                    title: "开始时间",
                    value: formatDateTime(session.startTime),
                    icon: "clock"
                )
                
                InfoItem(
                    title: "持续时间",
                    value: formatDuration(session.duration),
                    icon: "timer"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// 信息项组件
struct InfoItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 体态时间分解卡片
struct PostureBreakdownCard: View {
    let stats: SessionStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("体态时间分解")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // 体态时间列表
            VStack(spacing: 12) {
                ForEach(PostureType.allCases, id: \.self) { postureType in
                    PostureTimeRow(
                        postureType: postureType,
                        time: stats.postureTimeBreakdown[postureType] ?? 0,
                        percentage: stats.posturePercentages[postureType] ?? 0
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// 体态时间行
struct PostureTimeRow: View {
    let postureType: PostureType
    let time: TimeInterval
    let percentage: Double
    
    var body: some View {
        HStack {
            // 体态类型和颜色指示器
            HStack(spacing: 8) {
                Circle()
                    .fill(postureType.swiftUIColor)
                    .frame(width: 12, height: 12)
                
                Text(postureType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // 时间和百分比
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(time))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        let seconds = Int(time.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// 体态百分比进度条卡片
struct PosturePercentageCard: View {
    let stats: SessionStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("体态分布")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // 水平进度条
            VStack(spacing: 12) {
                ForEach(PostureType.allCases, id: \.self) { postureType in
                    PostureProgressBar(
                        postureType: postureType,
                        percentage: stats.posturePercentages[postureType] ?? 0
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// 体态进度条
struct PostureProgressBar: View {
    let postureType: PostureType
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(postureType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(postureType.swiftUIColor)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // 进度
                    Rectangle()
                        .fill(postureType.swiftUIColor)
                        .frame(width: geometry.size.width * (percentage / 100), height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.5), value: percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

/// 体态时间轴图表卡片
struct PostureTimelineCard: View {
    let session: PomodoroSession
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("体态变化时间轴")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // 时间轴图表
            PostureTimelineChart(timelineData: SessionTimelineData(from: session))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// 其他统计信息卡片
struct AdditionalStatsCard: View {
    let stats: SessionStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("其他统计")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // 统计项目
            HStack(spacing: 20) {
                StatisticItem(
                    title: "体态变化次数",
                    value: "\(stats.postureChanges)",
                    color: .blue
                )
                
                StatisticItem(
                    title: "最长优秀时间",
                    value: stats.formattedLongestStreak,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// 分享按钮
struct ShareButton: View {
    let session: PomodoroSession
    
    var body: some View {
        Button(action: shareSession) {
            Image(systemName: "square.and.arrow.up")
        }
    }
    
    private func shareSession() {
        let shareText = """
        HealthyCode 工作会话统计
        
        开始时间: \(formatDateTime(session.startTime))
        持续时间: \(formatDuration(session.duration))
        健康分数: \(String(format: "%.1f%%", session.healthScore))
        
        保持健康的工作姿势！
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    // 创建示例数据
    let sampleSession = PomodoroSession(
        startTime: Date(),
        duration: 25 * 60, // 25分钟
        postureData: [
            PostureRecord(posture: .excellent, startTime: Date(), duration: 15 * 60),
            PostureRecord(posture: .lookingDown, startTime: Date().addingTimeInterval(15 * 60), duration: 5 * 60),
            PostureRecord(posture: .tilted, startTime: Date().addingTimeInterval(20 * 60), duration: 3 * 60),
            PostureRecord(posture: .tooClose, startTime: Date().addingTimeInterval(23 * 60), duration: 2 * 60)
        ]
    )
    
    SessionDetailView(session: sampleSession, statisticsService: StatisticsService())
}