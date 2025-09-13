//
//  SettingsView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import SwiftUI

/// 设置界面，提供应用配置选项
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let onSettingsChanged: ((AppSettings) -> Void)?
    
    /// 初始化设置界面
    /// - Parameters:
    ///   - settingsService: 设置服务，可选
    ///   - statisticsService: 统计服务，可选
    ///   - onSettingsChanged: 设置变更回调，可选
    init(
        settingsService: (any SettingsServiceProtocol)? = nil, 
        statisticsService: (any StatisticsServiceProtocol)? = nil,
        onSettingsChanged: ((AppSettings) -> Void)? = nil
    ) {
        self.onSettingsChanged = onSettingsChanged
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(
            settingsService: settingsService ?? SettingsService(),
            statisticsService: statisticsService ?? StatisticsService(),
            onSettingsChanged: onSettingsChanged
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 番茄时钟设置
                Section("番茄时钟设置") {
                    workDurationSetting
                    breakDurationSetting
                }
                
                // 提醒设置
                Section("提醒设置") {
                    hapticFeedbackToggle
                    audioAlertsToggle
                }
                
                // 体态检测设置
                Section("体态检测设置") {
                    cameraDetectionToggle
                }
                
                // 数据管理
                Section("数据管理") {
                    resetSettingsButton
                    clearDataButton
                }
                
                // 应用信息
                Section("应用信息") {
                    appVersionInfo
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.primaryBlue)
                }
            }
        }
        .alert("重置设置", isPresented: $viewModel.showingResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                viewModel.resetSettings()
            }
        } message: {
            Text("这将重置所有设置为默认值。此操作无法撤销。")
        }
        .alert("清除所有数据", isPresented: $viewModel.showingDataClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                viewModel.clearAllData()
            }
        } message: {
            Text("这将删除所有会话历史记录和设置。此操作无法撤销。")
        }
    }
}

// MARK: - 设置组件
extension SettingsView {
    /// 工作时长设置
    private var workDurationSetting: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("工作时长")
                    .foregroundColor(.adaptiveText)
                Spacer()
                Text(viewModel.formatDuration(viewModel.currentWorkDuration))
                    .foregroundColor(.adaptiveSecondaryText)
                    .font(.system(.body, design: .monospaced))
            }
            
            Slider(
                value: Binding(
                    get: { viewModel.currentWorkDuration },
                    set: { viewModel.updateWorkDuration($0) }
                ),
                in: viewModel.workDurationRange,
                step: 5
            ) {
                Text("工作时长")
            } minimumValueLabel: {
                Text("5分")
                    .font(.caption)
                    .foregroundColor(.adaptiveSecondaryText)
            } maximumValueLabel: {
                Text("60分")
                    .font(.caption)
                    .foregroundColor(.adaptiveSecondaryText)
            }
            .accentColor(.primaryBlue)
        }
        .padding(.vertical, 4)
    }
    
    /// 休息时长设置
    private var breakDurationSetting: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("休息时长")
                    .foregroundColor(.adaptiveText)
                Spacer()
                Text(viewModel.formatDuration(viewModel.currentBreakDuration))
                    .foregroundColor(.adaptiveSecondaryText)
                    .font(.system(.body, design: .monospaced))
            }
            
            Slider(
                value: Binding(
                    get: { viewModel.currentBreakDuration },
                    set: { viewModel.updateBreakDuration($0) }
                ),
                in: viewModel.breakDurationRange,
                step: 1
            ) {
                Text("休息时长")
            } minimumValueLabel: {
                Text("1分")
                    .font(.caption)
                    .foregroundColor(.adaptiveSecondaryText)
            } maximumValueLabel: {
                Text("30分")
                    .font(.caption)
                    .foregroundColor(.adaptiveSecondaryText)
            }
            .accentColor(.primaryBlue)
        }
        .padding(.vertical, 4)
    }
    
    /// 触觉反馈开关
    private var hapticFeedbackToggle: some View {
        Toggle("触觉反馈", isOn: Binding(
            get: { viewModel.settingsService.settings.enableHapticFeedback },
            set: { _ in viewModel.toggleHapticFeedback() }
        ))
        .foregroundColor(.adaptiveText)
        .tint(.primaryBlue)
    }
    
    /// 音频提醒开关
    private var audioAlertsToggle: some View {
        Toggle("音频提醒", isOn: Binding(
            get: { viewModel.settingsService.settings.enableAudioAlerts },
            set: { _ in viewModel.toggleAudioAlerts() }
        ))
        .foregroundColor(.adaptiveText)
        .tint(.primaryBlue)
    }
    
    /// 摄像头检测开关
    private var cameraDetectionToggle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("体态检测", isOn: Binding(
                get: { viewModel.settingsService.settings.enableCameraDetection },
                set: { _ in viewModel.toggleCameraDetection() }
            ))
            .foregroundColor(.adaptiveText)
            .tint(.primaryBlue)
            
            if !viewModel.settingsService.settings.enableCameraDetection {
                Text("关闭后将只使用番茄时钟功能")
                    .font(.caption)
                    .foregroundColor(.adaptiveSecondaryText)
            }
        }
    }
    
    /// 重置设置按钮
    private var resetSettingsButton: some View {
        Button(action: {
            viewModel.showResetAlert()
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.warningOrange)
                Text("重置设置")
                    .foregroundColor(.warningOrange)
                Spacer()
            }
        }
    }
    
    /// 清除数据按钮
    private var clearDataButton: some View {
        Button(action: {
            viewModel.showDataClearAlert()
        }) {
            HStack {
                Image(systemName: "trash")
                    .foregroundColor(.alertRed)
                Text("清除所有数据")
                    .foregroundColor(.alertRed)
                Spacer()
            }
        }
    }
    
    /// 应用版本信息
    private var appVersionInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("版本")
                    .foregroundColor(.adaptiveText)
                Spacer()
                Text(appVersion)
                    .foregroundColor(.adaptiveSecondaryText)
                    .font(.system(.body, design: .monospaced))
            }
            
            HStack {
                Text("构建版本")
                    .foregroundColor(.adaptiveText)
                Spacer()
                Text(buildNumber)
                    .foregroundColor(.adaptiveSecondaryText)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }
    
    /// 应用版本号
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知"
    }
    
    /// 构建版本号
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知"
    }
}

// MARK: - 预览
#Preview {
    SettingsView()
}