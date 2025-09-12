//
//  PostureStatusView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI

/// 体态状态显示组件
struct PostureStatusView: View {
    // MARK: - Properties
    
    /// 当前体态类型
    let currentPosture: PostureType
    
    /// 不良体态持续时间
    let badPostureDuration: TimeInterval
    
    /// 是否正在检测
    let isDetecting: Bool
    
    /// 警告阈值
    let warningThreshold: TimeInterval
    
    // MARK: - Computed Properties
    
    /// 是否显示警告
    private var shouldShowWarning: Bool {
        !currentPosture.isHealthy && badPostureDuration >= warningThreshold
    }
    
    /// 状态图标名称
    private var statusIcon: String {
        switch currentPosture {
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
    
    /// 状态颜色
    private var statusColor: Color {
        if shouldShowWarning {
            return .red
        }
        return currentPosture.color
    }
    
    /// 进度条进度值
    private var warningProgress: Double {
        guard !currentPosture.isHealthy else { return 0 }
        return min(badPostureDuration / warningThreshold, 1.0)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            // 状态指示器
            statusIndicator
            
            // 体态状态文本
            postureStatusText
            
            // 警告进度条（仅在不良体态时显示）
            if !currentPosture.isHealthy {
                warningProgressBar
            }
            
            // 持续时间显示（仅在不良体态时显示）
            if !currentPosture.isHealthy && badPostureDuration > 0 {
                durationText
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: statusColor.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusColor, lineWidth: shouldShowWarning ? 3 : 2)
        )
        .animation(.easeInOut(duration: 0.3), value: currentPosture)
        .animation(.easeInOut(duration: 0.3), value: shouldShowWarning)
    }
    
    // MARK: - View Components
    
    /// 状态指示器
    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
                .scaleEffect(shouldShowWarning ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.3).repeatCount(shouldShowWarning ? .max : 1, autoreverses: true), value: shouldShowWarning)
            
            if !isDetecting {
                Image(systemName: "camera.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.6)
            }
        }
    }
    
    /// 体态状态文本
    private var postureStatusText: some View {
        VStack(spacing: 4) {
            Text(currentPosture.rawValue)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
            
            if !isDetecting {
                Text("摄像头未启用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if shouldShowWarning {
                Text("请调整体态")
                    .font(.caption)
                    .foregroundColor(.red)
                    .fontWeight(.medium)
            } else if currentPosture.isHealthy {
                Text("保持良好")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    /// 警告进度条
    private var warningProgressBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("警告倒计时")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(warningThreshold - badPostureDuration))s")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(warningProgress >= 1.0 ? .red : .orange)
            }
            
            ProgressView(value: warningProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: warningProgress >= 1.0 ? .red : .orange))
                .scaleEffect(y: 2)
        }
    }
    
    /// 持续时间文本
    private var durationText: some View {
        Text("持续时间: \(formatDuration(badPostureDuration))")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
            )
    }
    
    // MARK: - Helper Methods
    
    /// 格式化持续时间
    /// - Parameter duration: 持续时间（秒）
    /// - Returns: 格式化的时间字符串
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

struct PostureStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 优秀体态
            PostureStatusView(
                currentPosture: .excellent,
                badPostureDuration: 0,
                isDetecting: true,
                warningThreshold: 10
            )
            
            // 低头体态 - 警告前
            PostureStatusView(
                currentPosture: .lookingDown,
                badPostureDuration: 5,
                isDetecting: true,
                warningThreshold: 10
            )
            
            // 歪头体态 - 警告中
            PostureStatusView(
                currentPosture: .tilted,
                badPostureDuration: 12,
                isDetecting: true,
                warningThreshold: 10
            )
            
            // 太近体态 - 摄像头未启用
            PostureStatusView(
                currentPosture: .tooClose,
                badPostureDuration: 0,
                isDetecting: false,
                warningThreshold: 10
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}