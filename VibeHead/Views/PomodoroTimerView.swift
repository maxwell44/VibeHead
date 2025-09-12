//
//  PomodoroTimerView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI

/// 完整的番茄时钟界面，整合计时器显示和控制组件
struct PomodoroTimerView: View {
    /// 番茄时钟服务
    @ObservedObject var pomodoroService: PomodoroService
    
    /// 显示设置界面
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // 计时器显示
                TimerDisplayView(
                    timeRemaining: pomodoroService.timeRemaining,
                    totalTime: pomodoroService.settings.workDuration,
                    isRunning: pomodoroService.isRunning,
                    isPaused: pomodoroService.isPaused
                )
                
                // 工作时长显示
                workDurationInfo
                
                Spacer()
                
                // 控制按钮
                TimerControlsView(
                    isRunning: pomodoroService.isRunning,
                    isPaused: pomodoroService.isPaused,
                    settings: pomodoroService.settings,
                    onStart: {
                        pomodoroService.startSession()
                    },
                    onPause: {
                        pomodoroService.pauseSession()
                    },
                    onReset: {
                        pomodoroService.resetSession()
                    }
                )
                
                Spacer()
            }
            .padding()
            .background(Color.adaptiveBackground)
            .navigationTitle("番茄时钟")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("设置") {
                        showingSettings = true
                    }
                    .foregroundColor(.primaryBlue)
                }
            }
            .sheet(isPresented: $showingSettings) {
                // 设置界面（暂时用简单的文本替代）
                NavigationView {
                    VStack {
                        Text("设置界面")
                            .font(.title2)
                        Text("即将推出...")
                            .foregroundColor(.adaptiveSecondaryText)
                    }
                    .navigationTitle("设置")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完成") {
                                showingSettings = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 工作时长信息显示
    @ViewBuilder
    private var workDurationInfo: some View {
        VStack(spacing: 4) {
            Text("工作时长")
                .font(.caption)
                .foregroundColor(.adaptiveSecondaryText)
            
            Text("\(Int(pomodoroService.settings.workDuration / 60)) 分钟")
                .font(.headline)
                .foregroundColor(.adaptiveText)
        }
    }
}

#Preview {
    PomodoroTimerView(pomodoroService: PomodoroService())
}