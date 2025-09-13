//
//  WorkSessionView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI
import AVFoundation

/// 主工作界面，整合番茄时钟和体态检测功能
struct WorkSessionView: View {
    // MARK: - Properties
    @StateObject private var viewModel = WorkSessionViewModel()
    @State private var showingPermissionAlert = false
    @State private var showCameraTest = false
    @State private var showDirectCameraTest = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 主要内容区域
                    mainContentArea
                    
                    // 底部控制区域
                    bottomControlArea
                }
            }
            .navigationTitle("HealthyCode")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("🎯 WorkSessionView: View appeared")
            }
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $viewModel.showingStats) {
                statisticsSheet
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                settingsSheet
            }
            .sheet(isPresented: $showCameraTest) {
                CameraTestView()
            }
            .sheet(isPresented: $showDirectCameraTest) {
                DirectCameraTestView()
            }
            .alert("摄像头权限", isPresented: $showingPermissionAlert) {
                Button("设置") {
                    openAppSettings()
                }
                Button("仅使用计时器", role: .cancel) {
                    viewModel.startWorkSession()
                }
            } message: {
                Text("需要摄像头权限来检测体态。您可以在设置中启用权限，或选择仅使用计时器功能。")
            }
            .alert("错误", isPresented: $viewModel.showingError) {
                Button("确定", role: .cancel) { }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    // MARK: - Main Content Area
    
    @ViewBuilder
    private var mainContentArea: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 摄像头预览和体态状态区域
                cameraAndPostureSection
                
                // 番茄时钟区域
                pomodoroTimerSection
                
                // 会话信息区域
                sessionInfoSection
            }
            .padding()
        }
    }
    
    // MARK: - Camera and Posture Section
    
    @ViewBuilder
    private var cameraAndPostureSection: some View {
        VStack(spacing: 16) {
            // 摄像头预览
            cameraPreviewArea
            
            // 体态状态显示
            PostureStatusView(
                currentPosture: viewModel.currentPosture,
                badPostureDuration: viewModel.getCurrentBadPostureDuration(),
                isDetecting: viewModel.isDetecting,
                warningThreshold: viewModel.getCurrentSettings().badPostureWarningThreshold
            )
        }
    }
    
    @ViewBuilder
    private var cameraPreviewArea: some View {
        Group {
            switch viewModel.cameraPermissionStatus {
            case .authorized:
                if let previewLayer = viewModel.postureService.previewLayer {
                    CameraPreviewView(previewLayer: previewLayer)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(viewModel.currentPosture.swiftUIColor, lineWidth: 3)
                        )
                } else {
                    cameraPlaceholder
                }
                
            case .denied, .restricted:
                CameraUnavailableView()
                    .frame(height: 200)
                
            case .notDetermined:
                CameraPermissionView {
                    Task {
                        await viewModel.requestCameraPermission()
                    }
                }
                .frame(height: 200)
                
            @unknown default:
                cameraPlaceholder
            }
        }
    }
    
    @ViewBuilder
    private var cameraPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray5))
            .frame(height: 200)
            .overlay(
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("摄像头预览")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }
    
    // MARK: - Pomodoro Timer Section
    
    @ViewBuilder
    private var pomodoroTimerSection: some View {
        VStack(spacing: 20) {
            // 计时器显示
            TimerDisplayView(
                timeRemaining: viewModel.timeRemaining,
                totalTime: viewModel.getCurrentSettings().workDuration,
                isRunning: viewModel.isRunning,
                isPaused: viewModel.isPaused
            )
            
            // 进度指示器
            if viewModel.isRunning || viewModel.isPaused {
                progressIndicator
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveGroupedBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                Text("会话进度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(viewModel.getSessionProgress() * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: viewModel.getSessionProgress())
                .progressViewStyle(LinearProgressViewStyle(tint: .primaryBlue))
                .scaleEffect(y: 2)
        }
    }
    
    // MARK: - Session Info Section
    
    @ViewBuilder
    private var sessionInfoSection: some View {
        if viewModel.isRunning || viewModel.isPaused {
            VStack(spacing: 12) {
                HStack {
                    Text("当前会话")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(viewModel.sessionStateDescription)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(sessionStateColor.opacity(0.2))
                        )
                        .foregroundColor(sessionStateColor)
                }
                
                if viewModel.shouldShowPostureWarning() {
                    postureWarningBanner
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.adaptiveGroupedBackground)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    @ViewBuilder
    private var postureWarningBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.warningOrange)
            
            Text("请注意调整体态")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.warningOrange)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.warningOrange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.warningOrange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Bottom Control Area
    
    @ViewBuilder
    private var bottomControlArea: some View {
        VStack(spacing: 16) {
            Divider()
            
            HStack(spacing: 16) {
                // 主要操作按钮
                primaryActionButton
                
                // 重置按钮（仅在运行或暂停时显示）
                if viewModel.showResetButton {
                    resetButton
                }
                
                // 统计按钮（仅在有完成会话时显示）
                if viewModel.showStatsButton {
                    statsButton
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.adaptiveBackground)
    }
    
    @ViewBuilder
    private var primaryActionButton: some View {
        Button(action: handlePrimaryAction) {
            HStack {
                Image(systemName: primaryActionIcon)
                    .font(.headline)
                
                Text(viewModel.primaryButtonTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(primaryActionColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
        .disabled(!canPerformPrimaryAction)
    }
    
    @ViewBuilder
    private var resetButton: some View {
        Button(action: viewModel.resetSession) {
            Image(systemName: "arrow.clockwise")
                .font(.headline)
                .frame(width: 50, height: 50)
                .background(Color.secondary.opacity(0.2))
                .foregroundColor(.secondary)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private var statsButton: some View {
        Button(action: viewModel.showStatistics) {
            Image(systemName: "chart.bar.fill")
                .font(.headline)
                .frame(width: 50, height: 50)
                .background(Color.primaryBlue.opacity(0.2))
                .foregroundColor(.primaryBlue)
                .clipShape(Circle())
        }
    }
    
    // MARK: - Toolbar Content
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button("设置") {
                    viewModel.showSettings()
                }
                
                Button("摄像头测试") {
                    showCameraTest = true
                }
                
                Button("直接摄像头测试") {
                    showDirectCameraTest = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.primaryBlue)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.completedSession != nil {
                Button("统计") {
                    viewModel.showStatistics()
                }
                .foregroundColor(.primaryBlue)
            }
        }
    }
    
    // MARK: - Sheet Views
    
    @ViewBuilder
    private var statisticsSheet: some View {
        NavigationView {
            if let session = viewModel.completedSession {
                SessionDetailView(session: session, statisticsService: viewModel.statisticsService as! StatisticsService)
                    .navigationTitle("会话统计")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完成") {
                                viewModel.hideStatistics()
                            }
                        }
                    }
            } else {
                StatisticsView()
                    .navigationTitle("统计")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("完成") {
                                viewModel.hideStatistics()
                            }
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private var settingsSheet: some View {
        SettingsView(
            statisticsService: viewModel.statisticsService,
            onSettingsChanged: { settings in
                viewModel.updateSettings(settings)
            }
        )
    }
    
    // MARK: - Computed Properties
    
    private var sessionStateColor: Color {
        switch viewModel.sessionState {
        case .idle:
            return .secondary
        case .running:
            return .healthyGreen
        case .paused:
            return .warningOrange
        case .completed:
            return .primaryBlue
        case .error:
            return .alertRed
        }
    }
    
    private var primaryActionIcon: String {
        switch viewModel.sessionState {
        case .idle, .completed, .error:
            return "play.fill"
        case .running:
            return "pause.fill"
        case .paused:
            return "play.fill"
        }
    }
    
    private var primaryActionColor: Color {
        switch viewModel.sessionState {
        case .idle, .completed:
            return .healthyGreen
        case .running:
            return .warningOrange
        case .paused:
            return .healthyGreen
        case .error:
            return .alertRed
        }
    }
    
    private var canPerformPrimaryAction: Bool {
        switch viewModel.sessionState {
        case .idle:
            return true
        case .running, .paused:
            return true
        case .completed:
            return true
        case .error:
            return true
        }
    }
    
    // MARK: - Methods
    
    private func setupInitialState() {
        // 检查摄像头权限状态
        if viewModel.cameraPermissionStatus == .notDetermined {
            // 可以选择自动请求权限或等待用户操作
        }
    }
    
    private func handlePrimaryAction() {
        switch viewModel.sessionState {
        case .idle, .completed:
            if viewModel.cameraPermissionStatus == .denied || viewModel.cameraPermissionStatus == .restricted {
                showingPermissionAlert = true
            } else {
                viewModel.startWorkSession()
            }
            
        case .running:
            viewModel.pauseSession()
            
        case .paused:
            viewModel.resumeSession()
            
        case .error:
            viewModel.resetSession()
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Preview

struct WorkSessionView_Previews: PreviewProvider {
    static var previews: some View {
        WorkSessionView()
            .preferredColorScheme(.light)
        
        WorkSessionView()
            .preferredColorScheme(.dark)
    }
}