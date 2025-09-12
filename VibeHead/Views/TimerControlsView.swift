//
//  TimerControlsView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI

/// 计时器控制按钮组件，包含开始、暂停、重置等操作
struct TimerControlsView: View {
    /// 是否正在运行
    let isRunning: Bool
    
    /// 是否暂停
    let isPaused: Bool
    
    /// 应用设置
    let settings: AppSettings
    
    /// 开始/恢复会话回调
    let onStart: () -> Void
    
    /// 暂停会话回调
    let onPause: () -> Void
    
    /// 重置会话回调
    let onReset: () -> Void
    
    /// 反馈服务
    private let feedbackService = FeedbackService()
    
    var body: some View {
        HStack(spacing: 20) {
            // 重置按钮
            resetButton
            
            Spacer()
            
            // 主要操作按钮（开始/暂停/恢复）
            primaryActionButton
            
            Spacer()
            
            // 占位符，保持对称
            Color.clear
                .frame(width: 60, height: 60)
        }
        .padding(.horizontal, 40)
    }
    
    /// 主要操作按钮
    @ViewBuilder
    private var primaryActionButton: some View {
        Button(action: primaryAction) {
            ZStack {
                Circle()
                    .fill(primaryButtonColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: primaryButtonColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: primaryButtonIcon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isRunning && !isPaused ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isRunning && !isPaused)
    }
    
    /// 重置按钮
    @ViewBuilder
    private var resetButton: some View {
        Button(action: resetAction) {
            ZStack {
                Circle()
                    .fill(Color.adaptiveSecondaryText.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.adaptiveSecondaryText)
            }
        }
        .disabled(!isRunning && !isPaused)
        .opacity((isRunning || isPaused) ? 1.0 : 0.5)
    }
    
    /// 主要操作
    private func primaryAction() {
        feedbackService.playFeedback(type: .buttonTap, settings: settings)
        
        if isRunning && !isPaused {
            onPause()
        } else {
            onStart()
        }
    }
    
    /// 重置操作
    private func resetAction() {
        feedbackService.playFeedback(type: .buttonTap, settings: settings)
        onReset()
    }
    
    /// 主要按钮颜色
    private var primaryButtonColor: Color {
        if isPaused {
            return .healthyGreen
        } else if isRunning {
            return .warningOrange
        } else {
            return .primaryBlue
        }
    }
    
    /// 主要按钮图标
    private var primaryButtonIcon: String {
        if isPaused {
            return "play.fill"
        } else if isRunning {
            return "pause.fill"
        } else {
            return "play.fill"
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        // 准备状态
        TimerControlsView(
            isRunning: false,
            isPaused: false,
            settings: .default,
            onStart: { print("Start") },
            onPause: { print("Pause") },
            onReset: { print("Reset") }
        )
        
        // 运行状态
        TimerControlsView(
            isRunning: true,
            isPaused: false,
            settings: .default,
            onStart: { print("Start") },
            onPause: { print("Pause") },
            onReset: { print("Reset") }
        )
        
        // 暂停状态
        TimerControlsView(
            isRunning: true,
            isPaused: true,
            settings: .default,
            onStart: { print("Resume") },
            onPause: { print("Pause") },
            onReset: { print("Reset") }
        )
    }
    .padding()
    .background(Color.adaptiveBackground)
}