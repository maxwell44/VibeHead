//
//  PostureMonitorView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI
import Combine
import AVFoundation

/// 体态监控主视图，集成体态检测和警告系统
struct PostureMonitorView: View {
    // MARK: - Properties
    
    @ObservedObject var postureDetectionService: PostureDetectionService
    @State private var settings = AppSettings.default
    @State private var showingSettings = false
    @State private var badPostureDuration: TimeInterval = 0
    
    // Timer for updating bad posture duration
    @State private var updateTimer: Timer?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // 摄像头预览区域
            cameraPreviewSection
            
            // 体态状态显示
            PostureStatusView(
                currentPosture: postureDetectionService.currentPosture,
                badPostureDuration: badPostureDuration,
                isDetecting: postureDetectionService.isDetecting,
                warningThreshold: settings.badPostureWarningThreshold
            )
            
            // 控制按钮
            controlButtons
            
            // 设置快捷开关
            settingsToggles
        }
        .padding()
        .onAppear {
            setupUpdateTimer()
            postureDetectionService.updateSettings(settings)
        }
        .onDisappear {
            stopUpdateTimer()
        }
        .sheet(isPresented: $showingSettings) {
            PostureSettingsView(settings: $settings) { newSettings in
                postureDetectionService.updateSettings(newSettings)
            }
        }
    }
    
    // MARK: - View Components
    
    /// 摄像头预览区域
    private var cameraPreviewSection: some View {
        VStack(spacing: 8) {
            if postureDetectionService.cameraPermissionStatus == .authorized {
                CameraPreviewView(previewLayer: postureDetectionService.previewLayer)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(postureDetectionService.currentPosture.color, lineWidth: 2)
                    )
            } else {
                cameraPermissionPrompt
            }
        }
    }
    
    /// 摄像头权限提示
    private var cameraPermissionPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("需要摄像头权限")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("启用摄像头以进行体态检测")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("请求权限") {
                Task {
                    await postureDetectionService.requestCameraPermission()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    /// 控制按钮
    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button(action: toggleDetection) {
                HStack {
                    Image(systemName: postureDetectionService.isDetecting ? "stop.circle.fill" : "play.circle.fill")
                    Text(postureDetectionService.isDetecting ? "停止检测" : "开始检测")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(postureDetectionService.cameraPermissionStatus != .authorized)
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.bordered)
        }
    }
    
    /// 设置快捷开关
    private var settingsToggles: some View {
        VStack(spacing: 12) {
            HStack {
                Text("快捷设置")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                Toggle("音频提醒", isOn: $settings.enableAudioAlerts)
                    .onChange(of: settings.enableAudioAlerts) {
                        postureDetectionService.updateSettings(settings)
                    }
                
                Toggle("触觉反馈", isOn: $settings.enableHapticFeedback)
                    .onChange(of: settings.enableHapticFeedback) {
                        postureDetectionService.updateSettings(settings)
                    }
                
                HStack {
                    Text("警告阈值")
                    Spacer()
                    Text("\(Int(settings.badPostureWarningThreshold))秒")
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $settings.badPostureWarningThreshold,
                    in: 5...30,
                    step: 5
                ) {
                    Text("警告阈值")
                } minimumValueLabel: {
                    Text("5s")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("30s")
                        .font(.caption)
                }
                .onChange(of: settings.badPostureWarningThreshold) {
                    postureDetectionService.updateSettings(settings)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Actions
    
    /// 切换检测状态
    private func toggleDetection() {
        if postureDetectionService.isDetecting {
            postureDetectionService.stopDetection()
        } else {
            postureDetectionService.startDetection()
        }
    }
    
    // MARK: - Timer Management
    
    /// 设置更新计时器
    private func setupUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            badPostureDuration = postureDetectionService.getCurrentBadPostureDuration()
        }
    }
    
    /// 停止更新计时器
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}

// MARK: - Settings View

/// 体态设置视图
struct PostureSettingsView: View {
    @Binding var settings: AppSettings
    let onSettingsChanged: (AppSettings) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("警告设置") {
                    HStack {
                        Text("警告阈值")
                        Spacer()
                        Text("\(Int(settings.badPostureWarningThreshold))秒")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $settings.badPostureWarningThreshold,
                        in: 5...60,
                        step: 5
                    )
                }
                
                Section("反馈设置") {
                    Toggle("音频提醒", isOn: $settings.enableAudioAlerts)
                    Toggle("触觉反馈", isOn: $settings.enableHapticFeedback)
                }
                
                Section("检测设置") {
                    HStack {
                        Text("检测间隔")
                        Spacer()
                        Text("\(settings.postureCheckInterval, specifier: "%.1f")秒")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $settings.postureCheckInterval,
                        in: 0.5...3.0,
                        step: 0.5
                    )
                }
            }
            .navigationTitle("体态检测设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onSettingsChanged(settings)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct PostureMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        PostureMonitorView(postureDetectionService: PostureDetectionService())
    }
}