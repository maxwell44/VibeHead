//
//  PostureDetectionServiceProtocol.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation
import AVFoundation
import Combine

/// 体态检测服务协议，定义实时体态监控功能
protocol PostureDetectionServiceProtocol: ObservableObject {
    /// 当前检测到的体态
    var currentPosture: PostureType { get }
    
    /// 是否正在检测
    var isDetecting: Bool { get }
    
    /// 摄像头权限状态
    var cameraPermissionStatus: AVAuthorizationStatus { get }
    
    /// 当前不良体态持续时间
    var badPostureDuration: TimeInterval { get }
    
    /// 体态变化发布者
    var postureChangePublisher: AnyPublisher<PostureType, Never> { get }
    
    /// 开始体态检测
    func startDetection()
    
    /// 停止体态检测
    func stopDetection()
    
    /// 请求摄像头权限
    /// - Returns: 是否获得权限
    func requestCameraPermission() async -> Bool
    
    /// 检查设备是否支持体态检测
    /// - Returns: 是否支持
    func isPostureDetectionSupported() -> Bool
}