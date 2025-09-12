//
//  DeviceCapabilityChecker.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation
import AVFoundation
import Vision
import UIKit

/// 设备能力检测器，检查设备是否支持所需功能
class DeviceCapabilityChecker {
    
    /// 检查是否支持高级面部追踪
    /// - Returns: 是否支持高级面部追踪
    static func supportsAdvancedFaceTracking() -> Bool {
        if #available(iOS 11.0, *) {
            // 检查是否有前置摄像头和Vision Framework支持
            return hasFrontCamera() && supportsVisionFramework()
        }
        return false
    }
    
    /// 检查是否支持基础面部检测
    /// - Returns: 是否支持基础面部检测
    static func supportsBasicFaceDetection() -> Bool {
        if #available(iOS 11.0, *) {
            return hasFrontCamera() && supportsVisionFramework()
        }
        return false
    }
    
    /// 检查是否有前置摄像头
    /// - Returns: 是否有前置摄像头
    static func hasFrontCamera() -> Bool {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
    }
    
    /// 检查是否支持Vision Framework
    /// - Returns: 是否支持Vision Framework
    static func supportsVisionFramework() -> Bool {
        if #available(iOS 11.0, *) {
            return true
        }
        return false
    }
    
    /// 获取推荐的摄像头配置
    /// - Returns: 推荐的摄像头配置
    static func getRecommendedCameraConfiguration() -> (resolution: AVCaptureSession.Preset, frameRate: Int) {
        // 根据设备性能返回推荐配置
        let deviceModel = UIDevice.current.model
        
        if deviceModel.contains("iPhone") {
            // iPhone设备使用中等分辨率和15fps以节省电池
            return (.medium, 15)
        } else {
            // iPad设备可以使用更高配置
            return (.high, 20)
        }
    }
    
    /// 检查设备是否支持Core Haptics
    /// - Returns: 是否支持触觉反馈
    static func supportsHapticFeedback() -> Bool {
        if #available(iOS 13.0, *) {
            return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        }
        return false
    }
}

// MARK: - Core Haptics Import
import CoreHaptics