//
//  HealthyCodeApp.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import SwiftUI

/// HealthyCode应用主入口
@main
struct HealthyCodeApp: App {
    /// 数据仓库
    private let dataRepository = LocalDataRepository()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataRepository as LocalDataRepository)
        }
    }
}

/// 主内容视图，作为应用的根视图
struct ContentView: View {
    @EnvironmentObject private var dataRepository: LocalDataRepository
    @State private var appSettings: AppSettings = .default
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 应用标题
                Text("HealthyCode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // 副标题
                Text("健康编码 - 番茄工作法 + 体态检测")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // 占位内容 - 后续任务会实现具体功能
                VStack(spacing: 16) {
                    Image(systemName: "timer")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("准备开始您的健康工作之旅")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("结合番茄工作法和实时体态检测\n帮助您保持健康的工作习惯")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // 底部信息
                VStack(spacing: 8) {
                    Text("工作时长: \(appSettings.workDurationMinutes) 分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("休息时长: \(appSettings.breakDurationMinutes) 分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        appSettings = dataRepository.getAppSettings()
    }
}