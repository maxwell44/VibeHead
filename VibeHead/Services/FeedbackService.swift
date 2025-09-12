//
//  FeedbackService.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/12.
//

import Foundation
import AVFoundation
import CoreHaptics
import UIKit

/// 反馈服务，管理音频和触觉反馈
class FeedbackService {
    // MARK: - Properties
    
    /// 音频播放器
    private var audioPlayer: AVAudioPlayer?
    
    /// 触觉引擎
    private var hapticEngine: CHHapticEngine?
    
    /// 是否支持触觉反馈
    private var supportsHaptics: Bool {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    // MARK: - Initialization
    
    init() {
        setupAudio()
        setupHaptics()
    }
    
    // MARK: - Public Methods
    
    /// 播放会话完成提醒
    /// - Parameter enableAudio: 是否启用音频提醒
    func playSessionCompleteAlert(enableAudio: Bool) {
        if enableAudio {
            playCompletionSound()
        }
    }
    
    /// 播放体态警告反馈
    /// - Parameters:
    ///   - enableAudio: 是否启用音频提醒
    ///   - enableHaptic: 是否启用触觉反馈
    func playPostureWarning(enableAudio: Bool, enableHaptic: Bool) {
        if enableAudio {
            playWarningSound()
        }
        
        if enableHaptic {
            playWarningHaptic()
        }
    }
    
    /// 播放按钮点击反馈
    /// - Parameter enableHaptic: 是否启用触觉反馈
    func playButtonTap(enableHaptic: Bool) {
        if enableHaptic {
            playLightHaptic()
        }
    }
    
    /// 播放会话开始反馈
    /// - Parameter enableHaptic: 是否启用触觉反馈
    func playSessionStart(enableHaptic: Bool) {
        if enableHaptic {
            playSuccessHaptic()
        }
    }
    
    // MARK: - Private Methods - Audio Setup
    
    /// 设置音频会话
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    /// 播放完成音效
    private func playCompletionSound() {
        playSystemSound(soundID: 1016) // 系统完成音效
    }
    
    /// 播放警告音效
    private func playWarningSound() {
        playSystemSound(soundID: 1013) // 系统警告音效
    }
    
    /// 播放系统音效
    /// - Parameter soundID: 系统音效ID
    private func playSystemSound(soundID: UInt32) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    // MARK: - Private Methods - Haptic Setup
    
    /// 设置触觉引擎
    private func setupHaptics() {
        guard supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("触觉引擎设置失败: \(error)")
        }
    }
    
    /// 播放轻触觉反馈
    private func playLightHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// 播放成功触觉反馈
    private func playSuccessHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// 播放警告触觉反馈
    private func playWarningHaptic() {
        guard supportsHaptics, let engine = hapticEngine else {
            // 回退到基础触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            return
        }
        
        // 创建自定义触觉模式
        let warningPattern = createWarningHapticPattern()
        
        do {
            let player = try engine.makePlayer(with: warningPattern)
            try player.start(atTime: 0)
        } catch {
            print("触觉反馈播放失败: \(error)")
            // 回退到基础触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    /// 创建警告触觉模式
    /// - Returns: 触觉模式
    private func createWarningHapticPattern() -> CHHapticPattern {
        let events: [CHHapticEvent] = [
            // 第一次震动
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            ),
            // 短暂停顿后第二次震动
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0.2
            )
        ]
        
        do {
            return try CHHapticPattern(events: events, parameters: [])
        } catch {
            print("触觉模式创建失败: \(error)")
            // 返回简单的模式
            return try! CHHapticPattern(events: [events[0]], parameters: [])
        }
    }
}

// MARK: - Feedback Types Extension
extension FeedbackService {
    /// 反馈类型枚举
    enum FeedbackType {
        case sessionComplete
        case postureWarning
        case buttonTap
        case sessionStart
        
        /// 获取对应的音效ID
        var soundID: UInt32? {
            switch self {
            case .sessionComplete:
                return 1016 // 完成音效
            case .postureWarning:
                return 1013 // 警告音效
            case .buttonTap:
                return 1104 // 按键音效
            case .sessionStart:
                return 1000 // 开始音效
            }
        }
    }
    
    /// 播放指定类型的反馈
    /// - Parameters:
    ///   - type: 反馈类型
    ///   - settings: 应用设置
    func playFeedback(type: FeedbackType, settings: AppSettings) {
        switch type {
        case .sessionComplete:
            playSessionCompleteAlert(enableAudio: settings.enableAudioAlerts)
        case .postureWarning:
            playPostureWarning(
                enableAudio: settings.enableAudioAlerts,
                enableHaptic: settings.enableHapticFeedback
            )
        case .buttonTap:
            playButtonTap(enableHaptic: settings.enableHapticFeedback)
        case .sessionStart:
            playSessionStart(enableHaptic: settings.enableHapticFeedback)
        }
    }
}