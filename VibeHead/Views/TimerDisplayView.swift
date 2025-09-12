//
//  TimerDisplayView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI

/// 计时器显示组件，包含圆形进度指示器和时间显示
struct TimerDisplayView: View {
    /// 剩余时间（秒）
    let timeRemaining: TimeInterval
    
    /// 总时间（秒）
    let totalTime: TimeInterval
    
    /// 是否正在运行
    let isRunning: Bool
    
    /// 是否暂停
    let isPaused: Bool
    
    /// 计算进度百分比
    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return max(0, min(1, (totalTime - timeRemaining) / totalTime))
    }
    
    /// 格式化时间显示
    private var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 根据状态获取颜色
    private var progressColor: Color {
        if isPaused {
            return .warningOrange
        } else if isRunning {
            return .primaryBlue
        } else {
            return .adaptiveSecondaryText
        }
    }
    
    var body: some View {
        ZStack {
            // 圆形进度指示器
            CircularProgressView(
                progress: progress,
                color: progressColor,
                lineWidth: 12,
                size: 240,
                animated: true
            )
            
            VStack(spacing: 8) {
                // 时间显示
                Text(formattedTime)
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(.adaptiveText)
                
                // 状态指示器
                statusIndicator
            }
        }
    }
    
    /// 状态指示器
    @ViewBuilder
    private var statusIndicator: some View {
        if isPaused {
            HStack(spacing: 4) {
                Image(systemName: "pause.fill")
                Text("已暂停")
            }
            .font(.caption)
            .foregroundColor(.warningOrange)
        } else if isRunning {
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                Text("进行中")
            }
            .font(.caption)
            .foregroundColor(.primaryBlue)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text("准备开始")
            }
            .font(.caption)
            .foregroundColor(.adaptiveSecondaryText)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        // 运行状态
        TimerDisplayView(
            timeRemaining: 15 * 60 + 30, // 15:30
            totalTime: 25 * 60,
            isRunning: true,
            isPaused: false
        )
        
        // 暂停状态
        TimerDisplayView(
            timeRemaining: 10 * 60 + 45, // 10:45
            totalTime: 25 * 60,
            isRunning: true,
            isPaused: true
        )
        
        // 准备状态
        TimerDisplayView(
            timeRemaining: 25 * 60, // 25:00
            totalTime: 25 * 60,
            isRunning: false,
            isPaused: false
        )
    }
    .padding()
    .background(Color.adaptiveBackground)
}