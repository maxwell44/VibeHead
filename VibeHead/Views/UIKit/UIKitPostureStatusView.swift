//
//  UIKitPostureStatusView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import UIKit
import SnapKit

/// UIKit版本的体态状态显示组件
class UIKitPostureStatusView: UIView {
    
    // MARK: - Properties
    
    /// 当前体态类型
    private var currentPosture: PostureType = .excellent {
        didSet {
            updateUI()
        }
    }
    
    /// 不良体态持续时间
    private var badPostureDuration: TimeInterval = 0 {
        didSet {
            updateUI()
        }
    }
    
    /// 是否正在检测
    private var isDetecting: Bool = true {
        didSet {
            updateUI()
        }
    }
    
    /// 警告阈值
    private var warningThreshold: TimeInterval = 10 {
        didSet {
            updateUI()
        }
    }
    
    // MARK: - UI Components
    
    private let containerView = UIView()
    private let statusIndicatorStackView = UIStackView()
    private let statusIconImageView = UIImageView()
    private let cameraIconImageView = UIImageView()
    private let postureStatusStackView = UIStackView()
    private let postureStatusLabel = UILabel()
    private let statusDescriptionLabel = UILabel()
    private let warningProgressContainer = UIView()
    private let warningProgressStackView = UIStackView()
    private let warningTitleLabel = UILabel()
    private let warningTimeLabel = UILabel()
    private let warningProgressView = UIProgressView()
    private let durationLabel = UILabel()
    
    // MARK: - Computed Properties
    
    /// 是否显示警告
    private var shouldShowWarning: Bool {
        return !currentPosture.isHealthy && badPostureDuration >= warningThreshold
    }
    
    /// 状态图标名称
    private var statusIconName: String {
        switch currentPosture {
        case .excellent:
            return "checkmark.circle.fill"
        case .lookingDown:
            return "arrow.down.circle.fill"
        case .tilted:
            return "arrow.left.and.right.circle.fill"
        case .tooClose:
            return "exclamationmark.triangle.fill"
        case .notPresent:
            return "person.slash.fill"
        }
    }
    
    /// 状态颜色
    private var statusColor: UIColor {
        if shouldShowWarning {
            return .alertRed
        }
        return currentPosture.color
    }
    
    /// 进度条进度值
    private var warningProgress: Float {
        guard !currentPosture.isHealthy else { return 0 }
        return Float(min(badPostureDuration / warningThreshold, 1.0))
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        updateUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        updateUI()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 配置容器视图
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.borderWidth = 2
        
        // 配置状态指示器堆栈视图
        statusIndicatorStackView.axis = .horizontal
        statusIndicatorStackView.alignment = .center
        statusIndicatorStackView.spacing = 8
        
        // 配置状态图标
        statusIconImageView.contentMode = .scaleAspectFit
        statusIconImageView.tintColor = .healthyGreen
        
        // 配置摄像头图标
        cameraIconImageView.image = UIImage(systemName: "camera.fill")
        cameraIconImageView.contentMode = .scaleAspectFit
        cameraIconImageView.tintColor = .secondaryLabel
        cameraIconImageView.alpha = 0.6
        
        // 配置体态状态堆栈视图
        postureStatusStackView.axis = .vertical
        postureStatusStackView.alignment = .center
        postureStatusStackView.spacing = 4
        
        // 配置体态状态标签
        postureStatusLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        postureStatusLabel.textAlignment = .center
        postureStatusLabel.textColor = .healthyGreen
        
        // 配置状态描述标签
        statusDescriptionLabel.font = .systemFont(ofSize: 12, weight: .regular)
        statusDescriptionLabel.textAlignment = .center
        statusDescriptionLabel.textColor = .secondaryLabel
        
        // 配置警告进度容器
        warningProgressContainer.isHidden = true
        
        // 配置警告进度堆栈视图
        warningProgressStackView.axis = .vertical
        warningProgressStackView.spacing = 4
        
        // 配置警告标题和时间标签的水平堆栈
        let warningHeaderStackView = UIStackView()
        warningHeaderStackView.axis = .horizontal
        warningHeaderStackView.distribution = .equalSpacing
        
        // 配置警告标题标签
        warningTitleLabel.text = "警告倒计时"
        warningTitleLabel.font = .systemFont(ofSize: 10, weight: .regular)
        warningTitleLabel.textColor = .secondaryLabel
        
        // 配置警告时间标签
        warningTimeLabel.font = .systemFont(ofSize: 10, weight: .medium)
        warningTimeLabel.textColor = .warningOrange
        
        // 配置警告进度条
        warningProgressView.progressTintColor = .warningOrange
        warningProgressView.trackTintColor = .systemGray5
        warningProgressView.transform = CGAffineTransform(scaleX: 1, y: 2)
        
        // 配置持续时间标签
        durationLabel.font = .systemFont(ofSize: 12, weight: .regular)
        durationLabel.textAlignment = .center
        durationLabel.textColor = .secondaryLabel
        durationLabel.backgroundColor = .systemGray6
        durationLabel.layer.cornerRadius = 12
        durationLabel.layer.masksToBounds = true
        durationLabel.isHidden = true
        
        // 添加子视图
        addSubview(containerView)
        
        containerView.addSubview(statusIndicatorStackView)
        statusIndicatorStackView.addArrangedSubview(statusIconImageView)
        statusIndicatorStackView.addArrangedSubview(cameraIconImageView)
        
        containerView.addSubview(postureStatusStackView)
        postureStatusStackView.addArrangedSubview(postureStatusLabel)
        postureStatusStackView.addArrangedSubview(statusDescriptionLabel)
        
        containerView.addSubview(warningProgressContainer)
        warningProgressContainer.addSubview(warningProgressStackView)
        
        warningHeaderStackView.addArrangedSubview(warningTitleLabel)
        warningHeaderStackView.addArrangedSubview(warningTimeLabel)
        
        warningProgressStackView.addArrangedSubview(warningHeaderStackView)
        warningProgressStackView.addArrangedSubview(warningProgressView)
        
        containerView.addSubview(durationLabel)
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        statusIndicatorStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
        }
        
        statusIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        
        cameraIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        postureStatusStackView.snp.makeConstraints { make in
            make.top.equalTo(statusIndicatorStackView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        warningProgressContainer.snp.makeConstraints { make in
            make.top.equalTo(postureStatusStackView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        warningProgressStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        durationLabel.snp.makeConstraints { make in
            make.top.equalTo(warningProgressContainer.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(24)
        }
    }
    
    // MARK: - Public Methods
    
    /// 更新体态状态显示
    /// - Parameters:
    ///   - posture: 当前体态类型
    ///   - duration: 不良体态持续时间
    ///   - detecting: 是否正在检测
    ///   - threshold: 警告阈值
    func updatePostureStatus(
        posture: PostureType,
        duration: TimeInterval,
        detecting: Bool,
        threshold: TimeInterval
    ) {
        currentPosture = posture
        badPostureDuration = duration
        isDetecting = detecting
        warningThreshold = threshold
    }
    
    // MARK: - Private Methods
    
    private func updateUI() {
        updateStatusIcon()
        updatePostureStatusText()
        updateWarningProgress()
        updateDurationText()
        updateContainerAppearance()
        animateChanges()
    }
    
    private func updateStatusIcon() {
        statusIconImageView.image = UIImage(systemName: statusIconName)
        statusIconImageView.tintColor = statusColor
        cameraIconImageView.isHidden = isDetecting
    }
    
    private func updatePostureStatusText() {
        postureStatusLabel.text = currentPosture.rawValue
        postureStatusLabel.textColor = statusColor
        
        if !isDetecting {
            statusDescriptionLabel.text = "摄像头未启用"
            statusDescriptionLabel.textColor = .secondaryLabel
        } else if shouldShowWarning {
            statusDescriptionLabel.text = "请调整体态"
            statusDescriptionLabel.textColor = .alertRed
        } else if currentPosture.isHealthy {
            statusDescriptionLabel.text = "保持良好"
            statusDescriptionLabel.textColor = .healthyGreen
        } else {
            statusDescriptionLabel.text = currentPosture.description
            statusDescriptionLabel.textColor = .secondaryLabel
        }
    }
    
    private func updateWarningProgress() {
        let shouldShowProgress = !currentPosture.isHealthy
        warningProgressContainer.isHidden = !shouldShowProgress
        
        if shouldShowProgress {
            let remainingTime = Int(warningThreshold - badPostureDuration)
            warningTimeLabel.text = "\(max(remainingTime, 0))s"
            warningTimeLabel.textColor = warningProgress >= 1.0 ? .alertRed : .warningOrange
            
            warningProgressView.setProgress(warningProgress, animated: true)
            warningProgressView.progressTintColor = warningProgress >= 1.0 ? .alertRed : .warningOrange
        }
    }
    
    private func updateDurationText() {
        let shouldShowDuration = !currentPosture.isHealthy && badPostureDuration > 0
        durationLabel.isHidden = !shouldShowDuration
        
        if shouldShowDuration {
            durationLabel.text = "  持续时间: \(formatDuration(badPostureDuration))  "
        }
    }
    
    private func updateContainerAppearance() {
        containerView.layer.borderColor = statusColor.cgColor
        containerView.layer.borderWidth = shouldShowWarning ? 3 : 2
        containerView.layer.shadowColor = statusColor.withAlphaComponent(0.3).cgColor
    }
    
    private func animateChanges() {
        // 图标缩放动画
        let iconScale: CGFloat = shouldShowWarning ? 1.2 : 1.0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.statusIconImageView.transform = CGAffineTransform(scaleX: iconScale, y: iconScale)
        })
        
        // 警告状态的脉冲动画
        if shouldShowWarning {
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = 0.6
            pulseAnimation.fromValue = 1.0
            pulseAnimation.toValue = 1.1
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .infinity
            statusIconImageView.layer.add(pulseAnimation, forKey: "pulse")
        } else {
            statusIconImageView.layer.removeAnimation(forKey: "pulse")
        }
        
        // 容器边框和阴影动画
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.layoutIfNeeded()
        })
    }
    
    /// 格式化持续时间
    /// - Parameter duration: 持续时间（秒）
    /// - Returns: 格式化的时间字符串
    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)秒"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)分\(remainingSeconds)秒"
        }
    }
}

// MARK: - Preview Support (for development)
#if DEBUG
extension UIKitPostureStatusView {
    /// 创建预览实例的便利方法
    static func createPreviewInstance(
        posture: PostureType = .excellent,
        duration: TimeInterval = 0,
        detecting: Bool = true,
        threshold: TimeInterval = 10
    ) -> UIKitPostureStatusView {
        let view = UIKitPostureStatusView()
        view.updatePostureStatus(
            posture: posture,
            duration: duration,
            detecting: detecting,
            threshold: threshold
        )
        return view
    }
}
#endif