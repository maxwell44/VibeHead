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
    
    var body: some View {
        WorkSessionView()
    }
}