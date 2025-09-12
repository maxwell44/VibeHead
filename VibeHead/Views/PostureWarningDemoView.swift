//
//  PostureWarningDemoView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI

/// 体态警告系统演示视图，用于测试和展示功能
struct PostureWarningDemoView: View {
    @StateObject private var postureDetectionService = PostureDetectionService()
    @State private var selectedPosture: PostureType = .excellent
    @State private var simulatedDuration: TimeInterval = 0
    @State private var isSimulating = false
    
    // Timer for simulation
    @State private var simulationTimer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 演示说明
                Text("体态警告系统演示")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("选择不同的体态类型来测试警告系统")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // 体态选择器
                postureSelector
                
                // 体态状态显示
                PostureStatusView(
                    currentPosture: selectedPosture,
                    badPostureDuration: simulatedDuration,
                    isDetecting: isSimulating,
                    warningThreshold: 10.0
                )
                
                // 控制按钮
                controlButtons
                
                // 体态监控视图（完整版本）
                if isSimulating {
                    PostureMonitorView(postureDetectionService: postureDetectionService)
                        .frame(maxHeight: 400)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("体态警告演示")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onDisappear {
            stopSimulation()
        }
    }
    
    // MARK: - View Components
    
    /// 体态选择器
    private var postureSelector: some View {
        VStack(spacing: 12) {
            Text("选择体态类型")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(PostureType.allCases, id: \.self) { posture in
                    Button(action: {
                        selectPosture(posture)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: iconForPosture(posture))
                                .font(.title2)
                                .foregroundColor(posture.color)
                            
                            Text(posture.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPosture == posture ? posture.color.opacity(0.2) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedPosture == posture ? posture.color : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    /// 控制按钮
    private var controlButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button(action: toggleSimulation) {
                    HStack {
                        Image(systemName: isSimulating ? "stop.circle.fill" : "play.circle.fill")
                        Text(isSimulating ? "停止模拟" : "开始模拟")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: resetSimulation) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重置")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            if isSimulating {
                Text("模拟时间: \(formatDuration(simulatedDuration))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Actions
    
    /// 选择体态类型
    private func selectPosture(_ posture: PostureType) {
        selectedPosture = posture
        
        // 如果选择了不良体态，重置计时器
        if !posture.isHealthy {
            simulatedDuration = 0
        }
    }
    
    /// 切换模拟状态
    private func toggleSimulation() {
        if isSimulating {
            stopSimulation()
        } else {
            startSimulation()
        }
    }
    
    /// 开始模拟
    private func startSimulation() {
        isSimulating = true
        simulatedDuration = 0
        
        // 启动计时器
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if !selectedPosture.isHealthy {
                simulatedDuration += 0.5
                
                // 模拟警告触发
                if simulatedDuration >= 10.0 && Int(simulatedDuration * 2) % 20 == 0 {
                    triggerWarningFeedback()
                }
            }
        }
    }
    
    /// 停止模拟
    private func stopSimulation() {
        isSimulating = false
        simulationTimer?.invalidate()
        simulationTimer = nil
    }
    
    /// 重置模拟
    private func resetSimulation() {
        stopSimulation()
        simulatedDuration = 0
        selectedPosture = .excellent
    }
    
    /// 触发警告反馈
    private func triggerWarningFeedback() {
        let feedbackService = FeedbackService()
        let settings = AppSettings.default
        
        feedbackService.playPostureWarning(
            enableAudio: settings.enableAudioAlerts,
            enableHaptic: settings.enableHapticFeedback
        )
    }
    
    // MARK: - Helper Methods
    
    /// 获取体态对应的图标
    private func iconForPosture(_ posture: PostureType) -> String {
        switch posture {
        case .excellent:
            return "checkmark.circle.fill"
        case .lookingDown:
            return "arrow.down.circle.fill"
        case .tilted:
            return "arrow.left.and.right.circle.fill"
        case .tooClose:
            return "exclamationmark.triangle.fill"
        }
    }
    
    /// 格式化持续时间
    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)秒"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)分\(remainingSeconds)秒"
        }
    }
}

// MARK: - Preview

struct PostureWarningDemoView_Previews: PreviewProvider {
    static var previews: some View {
        PostureWarningDemoView()
    }
}