//
//  PostureType.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation
import UIKit

/// 体态类型枚举，定义五种不同的体态状态
enum PostureType: String, CaseIterable, Codable {
    case excellent = "优雅"
    case lookingDown = "低头"
    case tilted = "歪头"
    case tooClose = "太近"
    case notPresent = "人不在"
    
    /// 每种体态对应的颜色
    var color: UIColor {
        switch self {
        case .excellent:
            return .healthyGreen
        case .lookingDown, .tilted, .tooClose:
            return .warningOrange
        case .notPresent:
            return .systemGray
        }
    }
    
    /// 判断是否为健康体态
    var isHealthy: Bool {
        return self == .excellent
    }
    
    /// 判断是否检测到人
    var isPersonPresent: Bool {
        return self != .notPresent
    }
    
    /// 体态描述
    var description: String {
        switch self {
        case .excellent:
            return "保持良好姿势"
        case .lookingDown:
            return "头部过度向下"
        case .tilted:
            return "头部左右倾斜"
        case .tooClose:
            return "距离屏幕太近"
        case .notPresent:
            return "未检测到人"
        }
    }
}

