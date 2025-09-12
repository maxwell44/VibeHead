//
//  PostureTimelineChart.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import SwiftUI
import Charts

/// 体态时间轴图表组件
struct PostureTimelineChart: View {
    let timelineData: SessionTimelineData
    @State private var selectedDate: Date?
    @State private var showingFullscreen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 图表标题和全屏按钮
            HStack {
                Text("体态变化时间轴")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingFullscreen = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // 主图表
            Chart(timelineData.postureTimeline) { data in
                RectangleMark(
                    xStart: .value("开始时间", data.startTime),
                    xEnd: .value("结束时间", data.endTime),
                    y: .value("体态", data.posture.rawValue),
                    height: .fixed(30)
                )
                .foregroundStyle(data.posture.color)
                .opacity(selectedDate == nil ? 0.8 : 
                    (selectedDate! >= data.startTime && selectedDate! <= data.endTime ? 1.0 : 0.4))
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks(values: .stride(by: .minute, count: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
            .chartXSelection(value: $selectedDate)
            .onTapGesture {
                // 点击空白区域清除选择
                if selectedDate != nil {
                    selectedDate = nil
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedDate)
            
            // 图例
            PostureChartLegend()
            
            // 选中时间信息
            if let selectedDate = selectedDate {
                SelectedTimeInfo(selectedDate: selectedDate, timelineData: timelineData)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                SessionSummaryInfo(timelineData: timelineData)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDate != nil)
        .sheet(isPresented: $showingFullscreen) {
            FullscreenTimelineView(timelineData: timelineData)
        }
    }
}

/// 图表图例组件
struct PostureChartLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(PostureType.allCases, id: \.self) { postureType in
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(postureType.color)
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                    
                    Text(postureType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/// 选中时间信息组件
struct SelectedTimeInfo: View {
    let selectedDate: Date
    let timelineData: SessionTimelineData
    
    private var selectedPosture: PostureType? {
        // 找到选中时间点对应的体态
        timelineData.postureTimeline.first { data in
            selectedDate >= data.startTime && selectedDate <= data.endTime
        }?.posture
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选中时间: \(formatTime())")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let posture = selectedPosture {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(posture.color)
                        .frame(width: 16, height: 16)
                        .cornerRadius(4)
                    
                    Text("当前体态: \(posture.rawValue)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(posture.color)
                }
            } else {
                Text("未检测到体态数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }
    
    private func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: selectedDate)
    }
}

/// 会话总结信息组件
struct SessionSummaryInfo: View {
    let timelineData: SessionTimelineData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("会话总览")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 16) {
                ForEach(PostureType.allCases, id: \.self) { postureType in
                    let duration = timelineData.postureTimeline
                        .filter { $0.posture == postureType }
                        .reduce(0) { $0 + $1.duration }
                    
                    let percentage = timelineData.totalDuration > 0 ? 
                        (duration / timelineData.totalDuration) * 100 : 0
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(postureType.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(formatDuration(duration))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(postureType.color)
                        
                        Text("\(Int(percentage))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// 全屏时间轴视图
struct FullscreenTimelineView: View {
    let timelineData: SessionTimelineData
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date?
    @State private var zoomLevel: Double = 1.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 缩放控制
                HStack {
                    Text("缩放级别")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $zoomLevel, in: 0.5...3.0, step: 0.1)
                        .frame(maxWidth: 200)
                    
                    Text(String(format: "%.1fx", zoomLevel))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
                .padding(.horizontal)
                
                // 大图表
                Chart(timelineData.postureTimeline) { data in
                    RectangleMark(
                        xStart: .value("开始时间", data.startTime),
                        xEnd: .value("结束时间", data.endTime),
                        y: .value("体态", data.posture.rawValue),
                        height: .fixed(50 * zoomLevel)
                    )
                    .foregroundStyle(data.posture.color)
                    .opacity(selectedDate == nil ? 0.8 : 
                        (selectedDate! >= data.startTime && selectedDate! <= data.endTime ? 1.0 : 0.4))
                    
                    // 添加选中时间的垂直线
                    if let selectedDate = selectedDate {
                        RuleMark(x: .value("选中时间", selectedDate))
                            .foregroundStyle(.red)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
                .frame(height: max(200, 200 * zoomLevel))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .minute, count: max(1, Int(5 / zoomLevel)))) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour().minute().second())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                    }
                }
                .chartXSelection(value: $selectedDate)
                .animation(.easeInOut(duration: 0.2), value: selectedDate)
                .animation(.easeInOut(duration: 0.3), value: zoomLevel)
                
                // 图例
                PostureChartLegend()
                
                // 详细信息
                if let selectedDate = selectedDate {
                    DetailedTimeInfo(selectedDate: selectedDate, timelineData: timelineData)
                } else {
                    DetailedSessionInfo(timelineData: timelineData)
                }
                
                Spacer()
            }
            .navigationTitle("体态时间轴详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 详细时间信息组件
struct DetailedTimeInfo: View {
    let selectedDate: Date
    let timelineData: SessionTimelineData
    
    private var selectedPostureData: PostureTimelineData? {
        timelineData.postureTimeline.first { data in
            selectedDate >= data.startTime && selectedDate <= data.endTime
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选中时间详情")
                .font(.headline)
                .fontWeight(.bold)
            
            if let postureData = selectedPostureData {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("时间:")
                            .fontWeight(.medium)
                        Text(formatTime(selectedDate))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("体态:")
                            .fontWeight(.medium)
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(postureData.posture.color)
                                .frame(width: 16, height: 16)
                                .cornerRadius(4)
                            Text(postureData.posture.rawValue)
                                .foregroundColor(postureData.posture.color)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Text("持续时间:")
                            .fontWeight(.medium)
                        Text(formatDuration(postureData.duration))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("时间段:")
                            .fontWeight(.medium)
                        Text("\(formatTime(postureData.startTime)) - \(formatTime(postureData.endTime))")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("未找到对应的体态数据")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// 详细会话信息组件
struct DetailedSessionInfo: View {
    let timelineData: SessionTimelineData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("会话总览")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("会话时长:")
                        .fontWeight(.medium)
                    Text(formatDuration(timelineData.totalDuration))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("体态变化次数:")
                        .fontWeight(.medium)
                    Text("\(timelineData.postureTimeline.count)")
                        .foregroundColor(.secondary)
                }
                
                Text("各体态时间分布:")
                    .fontWeight(.medium)
                    .padding(.top, 4)
                
                ForEach(PostureType.allCases, id: \.self) { postureType in
                    let duration = timelineData.postureTimeline
                        .filter { $0.posture == postureType }
                        .reduce(0) { $0 + $1.duration }
                    
                    let percentage = timelineData.totalDuration > 0 ? 
                        (duration / timelineData.totalDuration) * 100 : 0
                    
                    HStack {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(postureType.color)
                                .frame(width: 12, height: 12)
                                .cornerRadius(2)
                            Text(postureType.rawValue)
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Text(formatDuration(duration))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("(\(Int(percentage))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    let sampleSession = PomodoroSession(
        startTime: Date().addingTimeInterval(-1500), // 25分钟前
        duration: 1500, // 25分钟
        postureData: [
            PostureRecord(posture: .excellent, startTime: Date().addingTimeInterval(-1500), duration: 600),
            PostureRecord(posture: .lookingDown, startTime: Date().addingTimeInterval(-900), duration: 300),
            PostureRecord(posture: .excellent, startTime: Date().addingTimeInterval(-600), duration: 400),
            PostureRecord(posture: .tooClose, startTime: Date().addingTimeInterval(-200), duration: 200)
        ]
    )
    
    PostureTimelineChart(timelineData: SessionTimelineData(from: sampleSession))
        .padding()
}