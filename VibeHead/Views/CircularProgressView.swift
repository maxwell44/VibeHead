//
//  CircularProgressView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI

/// 圆形进度指示器，用于显示番茄时钟的倒计时进度
struct CircularProgressView: View {
    /// 当前进度 (0.0 - 1.0)
    let progress: Double
    
    /// 圆环颜色
    let color: Color
    
    /// 圆环宽度
    let lineWidth: CGFloat
    
    /// 圆环大小
    let size: CGFloat
    
    /// 是否显示动画
    let animated: Bool
    
    init(
        progress: Double,
        color: Color = .primaryBlue,
        lineWidth: CGFloat = 8,
        size: CGFloat = 200,
        animated: Bool = true
    ) {
        self.progress = max(0, min(1, progress))
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.animated = animated
    }
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90)) // 从顶部开始
                .animation(
                    animated ? .easeInOut(duration: 0.3) : .none,
                    value: progress
                )
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 30) {
        CircularProgressView(progress: 0.75)
        
        CircularProgressView(
            progress: 0.3,
            color: .healthyGreen,
            lineWidth: 12,
            size: 150
        )
        
        CircularProgressView(
            progress: 0.9,
            color: .warningOrange,
            lineWidth: 6,
            size: 100
        )
    }
    .padding()
}