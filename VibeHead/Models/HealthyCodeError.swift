//
//  HealthyCodeError.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation

/// HealthyCode应用的错误类型定义
enum HealthyCodeError: LocalizedError {
    case cameraPermissionDenied
    case cameraNotAvailable
    case visionFrameworkError(Error)
    case dataCorruption
    case sessionInProgress
    case invalidSettings
    case storageError
    
    var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return "需要摄像头权限来检测体态"
        case .cameraNotAvailable:
            return "摄像头不可用"
        case .visionFrameworkError(let error):
            return "体态检测错误: \(error.localizedDescription)"
        case .dataCorruption:
            return "数据损坏，请重置应用设置"
        case .sessionInProgress:
            return "当前有会话正在进行中"
        case .invalidSettings:
            return "设置参数无效"
        case .storageError:
            return "数据存储错误"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .cameraPermissionDenied:
            return "请在设置中允许摄像头权限，或使用仅计时器模式"
        case .cameraNotAvailable:
            return "请检查摄像头是否被其他应用占用"
        case .visionFrameworkError:
            return "请重启应用或重新启动设备"
        case .dataCorruption:
            return "建议重置应用数据"
        case .sessionInProgress:
            return "请先完成或停止当前会话"
        case .invalidSettings:
            return "请检查设置参数是否正确"
        case .storageError:
            return "请检查设备存储空间"
        }
    }
}