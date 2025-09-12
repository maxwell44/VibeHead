//
//  StatisticsView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI

/// 统计界面，显示会话总结和健康分数
struct StatisticsView: View {
    @StateObject private var statisticsService = StatisticsService()
    @State private var selectedSession: PomodoroSession?
    @State private var showingSessionDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 总体统计卡片
                    OverallStatisticsCard(statisticsService: statisticsService)
                    
                    // 最近会话列表
                    RecentSessionsList(
                        statisticsService: statisticsService,
                        selectedSession: $selectedSession,
                        showingSessionDetail: $showingSessionDetail
                    )
                }
                .padding()
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSessionDetail) {
                if let session = selectedSession {
                    SessionDetailView(session: session, statisticsService: statisticsService)
                }
            }
        }
    }
}

/// 总体统计卡片
struct OverallStatisticsCard: View {
    let statisticsService: StatisticsService
    @State private var healthTrends: HealthTrends?
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("总体统计")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if let trends = healthTrends {
                VStack(spacing: 12) {
                    // 平均健康分数
                    HealthScoreDisplay(
                        score: trends.averageHealthScore,
                        title: "平均健康分数"
                    )
                    
                    // 统计数据行
                    HStack(spacing: 20) {
                        StatisticItem(
                            title: "总会话数",
                            value: "\(trends.totalSessions)",
                            color: .blue
                        )
                        
                        StatisticItem(
                            title: "总工作时间",
                            value: formatWorkTime(trends.totalWorkTime),
                            color: .green
                        )
                        
                        StatisticItem(
                            title: "改善趋势",
                            value: String(format: "%.1f%%", trends.improvementTrend),
                            color: trends.improvementTrend >= 0 ? .green : .red
                        )
                    }
                }
            } else {
                Text("暂无统计数据")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            loadHealthTrends()
        }
    }
    
    private func loadHealthTrends() {
        healthTrends = statisticsService.calculateHealthTrends()
    }
    
    private func formatWorkTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// 健康分数显示组件
struct HealthScoreDisplay: View {
    let score: Double
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.1f%%", score))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 80...100:
            return .green
        case 60..<80:
            return .orange
        default:
            return .red
        }
    }
}

/// 统计项目组件
struct StatisticItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 最近会话列表
struct RecentSessionsList: View {
    let statisticsService: StatisticsService
    @Binding var selectedSession: PomodoroSession?
    @Binding var showingSessionDetail: Bool
    @State private var recentSessions: [PomodoroSession] = []
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("最近会话")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if recentSessions.isEmpty {
                Text("暂无会话记录")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentSessions, id: \.id) { session in
                        SessionRowView(session: session)
                            .onTapGesture {
                                selectedSession = session
                                showingSessionDetail = true
                            }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            loadRecentSessions()
        }
    }
    
    private func loadRecentSessions() {
        recentSessions = statisticsService.getRecentSessions(days: 7)
    }
}

/// 会话行视图
struct SessionRowView: View {
    let session: PomodoroSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(session.startTime))
                    .font(.headline)
                
                Text(formatDuration(session.duration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 健康分数
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f%%", session.healthScore))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(healthScoreColor)
                
                Text("健康分数")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 箭头指示器
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private var healthScoreColor: Color {
        switch session.healthScore {
        case 80...100:
            return .green
        case 60..<80:
            return .orange
        default:
            return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) 分钟"
    }
}

#Preview {
    StatisticsView()
}