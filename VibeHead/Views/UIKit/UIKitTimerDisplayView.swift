//
//  UIKitTimerDisplayView.swift
//  VibeHead
//
//  UIKit implementation of timer display component matching the design
//

import UIKit
import SnapKit

/// UIKit版本的计时器显示组件，包含圆形进度指示器和时间显示
/// 基于设计图实现，包含圆形进度环、中央时间显示和状态指示
class UIKitTimerDisplayView: UIView {
    
    // MARK: - Properties
    
    /// 当前剩余时间
    private var timeRemaining: TimeInterval = 0
    
    /// 总时间
    private var totalTime: TimeInterval = 0
    
    /// 是否正在运行
    private var isRunning: Bool = false
    
    /// 是否暂停
    private var isPaused: Bool = false
    
    // MARK: - UI Components
    
    /// 主容器视图
    private let containerView = UIView()
    
    /// 圆形进度指示器
    private let circularProgressView = UIKitCircularProgressView()
    
    /// 时间显示标签
    private let timeLabel = UILabel()
    
    /// 状态图标
    private let statusIconView = UIImageView()
    
    /// 状态文本标签
    private let statusLabel = UILabel()
    
    /// 状态容器视图
    private let statusStackView = UIStackView()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 配置容器视图 - 白色圆形背景
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 120 // 240/2 = 120
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 12
        
        // 配置时间标签 - 大号等宽字体
        timeLabel.font = UIFont.monospacedSystemFont(ofSize: 48, weight: .light)
        timeLabel.textAlignment = .center
        timeLabel.textColor = .label
        timeLabel.text = "25:00"
        
        // 配置状态图标
        statusIconView.contentMode = .scaleAspectFit
        statusIconView.tintColor = .secondaryLabel
        statusIconView.image = UIImage(systemName: "timer")
        
        // 配置状态标签
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.text = "准备开始"
        
        // 配置状态栈视图
        statusStackView.axis = .horizontal
        statusStackView.alignment = .center
        statusStackView.spacing = 6
        statusStackView.addArrangedSubview(statusIconView)
        statusStackView.addArrangedSubview(statusLabel)
        
        // 添加子视图层次
        addSubview(containerView)
        addSubview(circularProgressView) // 进度环在容器外层
        containerView.addSubview(timeLabel)
        containerView.addSubview(statusStackView)
    }
    
    private func setupConstraints() {
        // 容器视图约束 - 240x240的圆形
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(240)
        }
        
        // 圆形进度视图约束 - 与容器同大小同位置
        circularProgressView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(240)
        }
        
        // 时间标签约束 - 居中显示
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10) // 稍微向上偏移
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // 状态栈视图约束 - 在时间下方
        statusStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(timeLabel.snp.bottom).offset(12)
        }
        
        // 状态图标约束
        statusIconView.snp.makeConstraints { make in
            make.width.height.equalTo(14)
        }
        
        // 整个组件的约束
        self.snp.makeConstraints { make in
            make.width.height.equalTo(280) // 给进度环留出空间
        }
    }
    
    // MARK: - Public Methods
    
    /// 更新计时器显示
    /// - Parameters:
    ///   - timeRemaining: 剩余时间（秒）
    ///   - totalTime: 总时间（秒）
    ///   - isRunning: 是否正在运行
    ///   - isPaused: 是否暂停
    func updateTimer(timeRemaining: TimeInterval, totalTime: TimeInterval, isRunning: Bool, isPaused: Bool = false) {
        let oldTimeRemaining = self.timeRemaining
        
        self.timeRemaining = timeRemaining
        self.totalTime = totalTime
        self.isRunning = isRunning
        self.isPaused = isPaused
        
        // 更新时间显示
        updateTimeDisplay()
        
        // 更新进度 - 使用动画当时间变化较小时
        let shouldAnimate = abs(oldTimeRemaining - timeRemaining) < 2.0
        updateProgress(animated: shouldAnimate)
        
        // 更新状态显示
        updateStatusDisplay()
    }
    
    // MARK: - Private Methods
    
    /// 更新时间显示
    private func updateTimeDisplay() {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        let formattedTime = String(format: "%02d:%02d", minutes, seconds)
        
        // 使用淡入淡出动画更新时间
        UIView.transition(with: timeLabel, duration: 0.2, options: .transitionCrossDissolve) {
            self.timeLabel.text = formattedTime
        }
    }
    
    /// 更新进度显示
    /// - Parameter animated: 是否使用动画
    private func updateProgress(animated: Bool) {
        let progress = totalTime > 0 ? max(0, min(1, (totalTime - timeRemaining) / totalTime)) : 0
        let color = getProgressColor()
        
        circularProgressView.setProgress(progress, color: color, animated: animated)
    }
    
    /// 更新状态显示
    private func updateStatusDisplay() {
        let (icon, text, color) = getStatusInfo()
        
        // 使用动画更新状态
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.statusIconView.image = UIImage(systemName: icon)
            self.statusIconView.tintColor = color
            self.statusLabel.text = text
            self.statusLabel.textColor = color
        }
    }
    
    /// 获取进度颜色 - 基于设计图使用绿色系
    /// - Returns: 进度颜色
    private func getProgressColor() -> UIColor {
        if isPaused {
            return .systemOrange // 暂停时使用橙色
        } else if isRunning {
            return .systemGreen // 运行时使用绿色，匹配设计图
        } else {
            return .systemGray3 // 未开始时使用灰色
        }
    }
    
    /// 获取状态信息
    /// - Returns: (图标名称, 状态文本, 颜色)
    private func getStatusInfo() -> (String, String, UIColor) {
        if isPaused {
            return ("pause.fill", "已暂停", .systemOrange)
        } else if isRunning {
            return ("play.fill", "进行中", .systemGreen)
        } else {
            return ("timer", "准备开始", .systemGray)
        }
    }
}

// MARK: - UIKitCircularProgressView

/// 圆形进度指示器 - 实现类似设计图的圆环进度
private class UIKitCircularProgressView: UIView {
    
    // MARK: - Properties
    
    /// 背景圆环层
    private let backgroundLayer = CAShapeLayer()
    
    /// 进度圆环层
    private let progressLayer = CAShapeLayer()
    
    /// 当前进度
    private var currentProgress: Double = 0
    
    /// 线宽 - 匹配设计图的粗细
    private let lineWidth: CGFloat = 8
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerPaths()
    }
    
    // MARK: - Setup Methods
    
    private func setupLayers() {
        backgroundColor = .clear
        
        // 配置背景圆环 - 浅灰色背景
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = UIColor.systemGray5.cgColor
        backgroundLayer.lineWidth = lineWidth
        backgroundLayer.lineCap = .round
        
        // 配置进度圆环 - 绿色进度
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.systemGreen.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        
        // 添加到视图层
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
    }
    
    private func updateLayerPaths() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
        
        // 创建圆形路径 - 从顶部开始（-90度）
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -CGFloat.pi / 2, // 从12点方向开始
            endAngle: 3 * CGFloat.pi / 2, // 顺时针一圈
            clockwise: true
        )
        
        backgroundLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
    
    // MARK: - Public Methods
    
    /// 设置进度
    /// - Parameters:
    ///   - progress: 进度值 (0.0 - 1.0)
    ///   - color: 进度颜色
    ///   - animated: 是否使用动画
    func setProgress(_ progress: Double, color: UIColor, animated: Bool) {
        let clampedProgress = max(0, min(1, progress))
        
        // 更新颜色
        progressLayer.strokeColor = color.cgColor
        backgroundLayer.strokeColor = color.withAlphaComponent(0.2).cgColor
        
        if animated && abs(clampedProgress - currentProgress) > 0.001 {
            // 创建平滑的进度动画
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = currentProgress
            animation.toValue = clampedProgress
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            progressLayer.add(animation, forKey: "progressAnimation")
        }
        
        // 更新实际值
        progressLayer.strokeEnd = clampedProgress
        currentProgress = clampedProgress
    }
}