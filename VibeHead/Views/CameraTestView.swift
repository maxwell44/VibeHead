//
//  CameraTestView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import SwiftUI
import AVFoundation

/// 摄像头测试视图，用于调试摄像头问题
struct CameraTestView: View {
    @StateObject private var cameraService = CameraService()
    @State private var showingDebugInfo = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 权限状态
                statusSection
                
                // 摄像头预览
                cameraPreviewSection
                
                // 控制按钮
                controlSection
                
                // 调试信息
                if showingDebugInfo {
                    debugSection
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("摄像头测试")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                cameraService.checkCameraPermission()
            }
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("权限状态:")
                    .fontWeight(.medium)
                Spacer()
                Text(cameraService.authorizationStatus.localizedDescription)
                    .foregroundColor(statusColor)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("会话状态:")
                    .fontWeight(.medium)
                Spacer()
                Text(cameraService.isSessionRunning ? "运行中" : "已停止")
                    .foregroundColor(cameraService.isSessionRunning ? .green : .red)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var cameraPreviewSection: some View {
        VStack(spacing: 12) {
            Text("摄像头预览")
                .font(.headline)
            
            if cameraService.authorizationStatus == .authorized {
                if let previewLayer = cameraService.previewLayer {
                    CameraPreviewView(previewLayer: previewLayer)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                Text("预览层未创建")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.red.opacity(0.2))
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                            Text("需要摄像头权限")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    )
            }
        }
    }
    
    private var controlSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if cameraService.authorizationStatus == .notDetermined {
                    Button("请求权限") {
                        Task {
                            await cameraService.requestCameraPermission()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if cameraService.authorizationStatus == .authorized {
                    Button(cameraService.isSessionRunning ? "停止预览" : "开始预览") {
                        if cameraService.isSessionRunning {
                            cameraService.stopSession()
                        } else {
                            cameraService.startPreviewOnly()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            HStack(spacing: 12) {
                Button("调试信息") {
                    cameraService.debugCameraStatus()
                    showingDebugInfo.toggle()
                }
                .buttonStyle(.bordered)
                
                if cameraService.authorizationStatus == .authorized {
                    Button("重启摄像头") {
                        cameraService.restartCameraSession()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("调试信息")
                .font(.headline)
            
            Group {
                debugRow("会话输入数量", "\(cameraService.captureSession.inputs.count)")
                debugRow("会话输出数量", "\(cameraService.captureSession.outputs.count)")
                debugRow("预览层存在", cameraService.previewLayer != nil ? "是" : "否")
                
                if let previewLayer = cameraService.previewLayer {
                    debugRow("预览层连接", previewLayer.connection?.isEnabled == true ? "已启用" : "未启用")
                    debugRow("预览层会话", previewLayer.session === cameraService.captureSession ? "匹配" : "不匹配")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func debugRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private var statusColor: Color {
        switch cameraService.authorizationStatus {
        case .authorized:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

#Preview {
    CameraTestView()
}