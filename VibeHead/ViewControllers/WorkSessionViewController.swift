//
//  WorkSessionViewController.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import UIKit
import SnapKit
import AVFoundation
import Combine

/// 主工作会话视图控制器，管理番茄钟和体态检测功能
class WorkSessionViewController: BaseViewController {
    
    // MARK: - Properties
    private var viewModel: WorkSessionViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    // 主滚动视图
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private let contentView = UIView()
    
    // 摄像头预览区域 - 已移除
    
    // 体态状态视图
    private let postureStatusContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let postureStatusIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .healthyGreen
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let postureStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "优秀"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .healthyGreen
        label.textAlignment = .center
        return label
    }()
    
    private let postureSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "保持良好"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemGreen
        label.textAlignment = .center
        return label
    }()
    
    // 计时器显示区域 - 圆形设计
    private let timerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        return view
    }()
    
    // 圆形进度环
    private let progressRingLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.primaryBlue.cgColor
        layer.lineWidth = 8
        layer.lineCap = .round
        return layer
    }()
    
    private let progressBackgroundRingLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.systemGray5.cgColor
        layer.lineWidth = 8
        layer.lineCap = .round
        return layer
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.text = "25:00"
        label.font = .monospacedDigitSystemFont(ofSize: 48, weight: .light)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let timerStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "准备开始"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    // 圆环中心的设置图片
    private let centerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "a1")
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // progressView 已移除，使用圆形进度环替代
    
    // 会话信息区域 - 已移除
    
    // 体态警告横幅
    private let postureWarningView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.warningOrange.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.warningOrange.withAlphaComponent(0.3).cgColor
        view.isHidden = true
        return view
    }()
    
    private let warningIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        imageView.tintColor = .warningOrange
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = "请注意调整体态"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .warningOrange
        return label
    }()
    
    // 底部控制区域
    private let bottomControlView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let controlsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.spacing = 16
        return stackView
    }()
    
    private let primaryActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始工作", for: .normal)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.tintColor = .white
        button.backgroundColor = .healthyGreen
        button.layer.cornerRadius = 25
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        return button
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        button.tintColor = .secondaryLabel
        button.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.2)
        button.layer.cornerRadius = 25
        button.isHidden = true
        return button
    }()
    
    private let statsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chart.bar.fill"), for: .normal)
        button.tintColor = .primaryBlue
        button.backgroundColor = UIColor.primaryBlue.withAlphaComponent(0.2)
        button.layer.cornerRadius = 25
        button.isHidden = true
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🚀 WorkSessionViewController: 开始初始化")
        
        // 延迟初始化ViewModel以避免阻塞UI
        DispatchQueue.main.async { [weak self] in
            self?.initializeViewModel()
        }
        
        setupUI()
        setupConstraints()
        setupNavigationBar()
        setupInitialState()
        
        print("🚀 WorkSessionViewController: 视图控制器加载完成")
    }
    
    private func initializeViewModel() {
        print("🚀 WorkSessionViewController: 开始初始化ViewModel")
        viewModel = WorkSessionViewModel()
        setupBindings()
        updateUI()
        print("🚀 WorkSessionViewController: ViewModel初始化完成")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "HealthyCode"
        
        // 添加主要视图层次结构
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 摄像头预览区域 - 已移除
        
        // 体态状态区域
        contentView.addSubview(postureStatusContainerView)
        postureStatusContainerView.addSubview(postureStatusIconView)
        postureStatusContainerView.addSubview(postureStatusLabel)
        postureStatusContainerView.addSubview(postureSubtitleLabel)
        
        // 计时器区域 - 圆形设计
        contentView.addSubview(timerContainerView)
        timerContainerView.addSubview(timerLabel)
        timerContainerView.addSubview(timerStatusLabel)
        timerContainerView.addSubview(centerImageView)
        
        // 添加圆形进度环
        timerContainerView.layer.addSublayer(progressBackgroundRingLayer)
        timerContainerView.layer.addSublayer(progressRingLayer)
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(centerImageTapped))
        centerImageView.addGestureRecognizer(tapGesture)
        
        // 会话信息区域 - 已移除
        
        // 底部控制区域
        view.addSubview(bottomControlView)
        bottomControlView.addSubview(controlsStackView)
        controlsStackView.addArrangedSubview(primaryActionButton)
        controlsStackView.addArrangedSubview(resetButton)
        controlsStackView.addArrangedSubview(statsButton)
        
        // 设置按钮动作
        primaryActionButton.addTarget(self, action: #selector(primaryActionTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        statsButton.addTarget(self, action: #selector(statsButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        // 滚动视图约束
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(bottomControlView.snp.top)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // 摄像头预览区域约束 - 已移除
        
        // 体态状态区域约束
        postureStatusContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        postureStatusIconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        postureStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(postureStatusIconView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        postureSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(postureStatusLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }
        
        // 计时器区域约束 - 圆形设计
        timerContainerView.snp.makeConstraints { make in
            make.top.equalTo(postureStatusContainerView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(280)
            make.bottom.equalToSuperview().offset(-32)
        }
        
        timerLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        
        timerStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(timerLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        
        centerImageView.snp.makeConstraints { make in
            make.bottom.equalTo(timerLabel.snp.top).offset(-20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(60)
        }
        
        // 会话信息区域约束 - 已移除
        
        // 底部控制区域约束
        bottomControlView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        controlsStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(50)
        }
        
        // 按钮约束
        resetButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        
        statsButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
    }
    
    private func setupBindings() {
        // 使用定时器更新UI状态
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
        
        // 监听错误状态
        viewModel.$showingError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showingError in
                if showingError, let errorMessage = self?.viewModel.errorMessage {
                    self?.showAlert(title: "错误", message: errorMessage)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        
        // 左侧菜单按钮
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(menuButtonTapped)
        )
        menuButton.tintColor = .primaryBlue
        navigationItem.leftBarButtonItem = menuButton
        
        // 右侧摄像头测试按钮
        let cameraTestButton = UIBarButtonItem(
            image: UIImage(systemName: "camera.fill"),
            style: .plain,
            target: self,
            action: #selector(cameraTestButtonTapped)
        )
        cameraTestButton.tintColor = .primaryBlue
        navigationItem.rightBarButtonItem = cameraTestButton
        
        // 右侧统计按钮（条件显示）
        updateNavigationBarButtons()
    }
    
    private func setupInitialState() {
        updateUI()
    }
    
    // MARK: - UI Update Methods
    
    private func updateUI() {
        guard viewModel != nil else { return }
        updateTimerDisplay()
        updatePostureStatus()
        updateControlButtons()
        updateNavigationBarButtons()
    }
    
    private func updateTimerDisplay() {
        guard let viewModel = viewModel else { return }
        
        let timeRemaining = viewModel.timeRemaining
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        // 更新圆形进度
        let progress = viewModel.getSessionProgress()
        updateCircularProgress(progress: progress)
        
        // 更新状态标签和颜色
        switch viewModel.sessionState {
        case .idle:
            timerStatusLabel.text = "准备开始"
            timerStatusLabel.textColor = .secondaryLabel
            progressRingLayer.strokeColor = UIColor.systemGray4.cgColor
        case .running:
            timerStatusLabel.text = "进行中"
            timerStatusLabel.textColor = .primaryBlue
            progressRingLayer.strokeColor = UIColor.primaryBlue.cgColor
        case .paused:
            timerStatusLabel.text = "已暂停"
            timerStatusLabel.textColor = .warningOrange
            progressRingLayer.strokeColor = UIColor.warningOrange.cgColor
        case .completed:
            timerStatusLabel.text = "已完成"
            timerStatusLabel.textColor = .healthyGreen
            progressRingLayer.strokeColor = UIColor.healthyGreen.cgColor
        case .error:
            timerStatusLabel.text = "错误"
            timerStatusLabel.textColor = .alertRed
            progressRingLayer.strokeColor = UIColor.alertRed.cgColor
        }
    }
    
    private func updateCircularProgress(progress: Double) {
        let center = CGPoint(x: timerContainerView.bounds.midX, y: timerContainerView.bounds.midY)
        let radius: CGFloat = 120
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        // 更新背景环
        let backgroundPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressBackgroundRingLayer.path = backgroundPath.cgPath
        
        // 更新进度环
        let progressEndAngle = startAngle + 2 * CGFloat.pi * CGFloat(progress)
        let progressPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: progressEndAngle, clockwise: true)
        progressRingLayer.path = progressPath.cgPath
    }
    
    private func updatePostureStatus() {
        guard let viewModel = viewModel else { return }
        
        let posture = viewModel.currentPosture
        let isDetecting = viewModel.isDetecting
        
        // 更新图标
        let iconName: String
        switch posture {
        case .excellent:
            iconName = "checkmark.circle.fill"
        case .lookingDown:
            iconName = "arrow.down.circle.fill"
        case .tilted:
            iconName = "arrow.left.and.right.circle.fill"
        case .tooClose:
            iconName = "exclamationmark.triangle.fill"
        }
        
        postureStatusIconView.image = UIImage(systemName: iconName)
        postureStatusIconView.tintColor = posture.color
        
        // 更新文本
        postureStatusLabel.text = posture.rawValue
        postureStatusLabel.textColor = posture.color
        
        // 更新副标题
        if !isDetecting {
            postureSubtitleLabel.text = "摄像头未启用"
            postureSubtitleLabel.textColor = .secondaryLabel
        } else if viewModel.shouldShowPostureWarning() {
            postureSubtitleLabel.text = "请调整体态"
            postureSubtitleLabel.textColor = .alertRed
        } else if posture.isHealthy {
            postureSubtitleLabel.text = "保持良好"
            postureSubtitleLabel.textColor = .systemGreen
        } else {
            postureSubtitleLabel.text = ""
        }
        
        // 更新边框颜色
        postureStatusContainerView.layer.borderWidth = viewModel.shouldShowPostureWarning() ? 3 : 0
        postureStatusContainerView.layer.borderColor = posture.color.cgColor
    }
    
    // updateSessionInfo 方法已移除，因为会话信息区域已被移除
    
    private func updateControlButtons() {
        guard let viewModel = viewModel else { return }
        
        // 更新主要操作按钮
        primaryActionButton.setTitle(viewModel.primaryButtonTitle, for: .normal)
        
        let iconName: String
        let backgroundColor: UIColor
        
        switch viewModel.sessionState {
        case .idle, .completed:
            iconName = "play.fill"
            backgroundColor = .healthyGreen
        case .running:
            iconName = "pause.fill"
            backgroundColor = .warningOrange
        case .paused:
            iconName = "play.fill"
            backgroundColor = .healthyGreen
        case .error:
            iconName = "arrow.clockwise"
            backgroundColor = .alertRed
        }
        
        primaryActionButton.setImage(UIImage(systemName: iconName), for: .normal)
        primaryActionButton.backgroundColor = backgroundColor
        
        // 更新辅助按钮显示状态
        resetButton.isHidden = !viewModel.showResetButton
        statsButton.isHidden = !viewModel.showStatsButton
    }
    
    private func updateNavigationBarButtons() {
        guard let viewModel = viewModel else { return }
        
        if viewModel.showStatsButton {
            let statsBarButton = UIBarButtonItem(
                title: "统计",
                style: .plain,
                target: self,
                action: #selector(statsButtonTapped)
            )
            statsBarButton.tintColor = .primaryBlue
            navigationItem.rightBarButtonItem = statsBarButton
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    // updateCameraPreview 和 setupCameraPreviewLayer 方法已移除，因为摄像头预览区域已被移除
    
    // MARK: - Action Methods
    
    @objc private func primaryActionTapped() {
        handlePrimaryAction()
    }
    
    @objc private func resetButtonTapped() {
        guard let viewModel = viewModel else { return }
        
        showConfirmation(
            title: "重置会话",
            message: "确定要重置当前会话吗？所有进度将丢失。",
            confirmTitle: "重置"
        ) {
            viewModel.resetSession()
        }
    }
    
    @objc private func statsButtonTapped() {
        guard let viewModel = viewModel else { return }
        
        viewModel.showStatistics()
        presentStatisticsViewController()
    }
    
    @objc private func menuButtonTapped() {
        showMenuActionSheet()
    }
    
    @objc private func cameraTestButtonTapped() {
        let cameraTestVC = CameraTestViewController()
        let navController = UINavigationController(rootViewController: cameraTestVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func centerImageTapped() {
        // 只有在空闲状态下才能设置时间
        guard let viewModel = viewModel, viewModel.sessionState == .idle else {
            return
        }
        
        showTimerSettingsAlert()
    }
    
    private func handlePrimaryAction() {
        guard let viewModel = viewModel else { return }
        
        switch viewModel.sessionState {
        case .idle, .completed:
            if viewModel.cameraPermissionStatus == .denied || viewModel.cameraPermissionStatus == .restricted {
                showCameraPermissionAlert()
            } else {
                viewModel.startWorkSession()
            }
        case .running:
            viewModel.pauseSession()
        case .paused:
            viewModel.resumeSession()
        case .error:
            viewModel.resetSession()
        }
    }
    
    private func showCameraPermissionAlert() {
        showAlert(
            title: "摄像头权限",
            message: "需要摄像头权限来检测体态。您可以在设置中启用权限，或选择仅使用计时器功能。",
            actions: [
                UIAlertAction(title: "设置", style: .default) { _ in
                    self.openAppSettings()
                },
                UIAlertAction(title: "仅使用计时器", style: .cancel) { _ in
                    self.viewModel.startWorkSession()
                }
            ]
        )
    }
    
    private func showMenuActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "设置", style: .default) { _ in
            self.presentSettingsViewController()
        })
        
        actionSheet.addAction(UIAlertAction(title: "摄像头测试", style: .default) { _ in
            self.presentCameraTestViewController()
        })
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // iPad支持
        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItem
        }
        
        present(actionSheet, animated: true)
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func showTimerSettingsAlert() {
        let alert = UIAlertController(title: "设置工作时长", message: "选择工作时长（分钟）", preferredStyle: .actionSheet)
        
        // 获取当前设置的分钟数
        let currentMinutes = Int(viewModel.getCurrentSettings().workDuration / 60)
        
        // 创建常用时间选项
        let timeOptions = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
        
        for minutes in timeOptions {
            let title = minutes == currentMinutes ? "✓ \(minutes) 分钟" : "\(minutes) 分钟"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.updateWorkDuration(minutes: minutes)
            })
        }
        
        // 取消按钮
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // iPad支持
        if let popover = alert.popoverPresentationController {
            popover.sourceView = centerImageView
            popover.sourceRect = centerImageView.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func updateWorkDuration(minutes: Int) {
        guard let viewModel = viewModel else { return }
        
        var settings = viewModel.getCurrentSettings()
        settings.workDurationMinutes = minutes
        viewModel.updateSettings(settings)
        
        // 更新UI显示
        updateUI()
        
        // 显示确认消息
        let message = "工作时长已设置为 \(minutes) 分钟"
        let confirmAlert = UIAlertController(title: "设置成功", message: message, preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: "确定", style: .default))
        present(confirmAlert, animated: true)
    }
    
    // MARK: - Navigation Methods
    
    private func presentStatisticsViewController() {
        // 这将在后续任务中实现
        print("📊 统计界面展示 - 待实现")
    }
    
    private func presentSettingsViewController() {
        // 这将在后续任务中实现
        print("⚙️ 设置界面展示 - 待实现")
    }
    
    private func presentCameraTestViewController() {
        // 这将在后续任务中实现
        print("📷 摄像头测试界面展示 - 待实现")
    }
    
    // MARK: - Layout Updates
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 设置圆形计时器容器
        setupCircularTimerContainer()
        
        // 更新圆形进度环的路径
        if let viewModel = viewModel {
            let progress = viewModel.getSessionProgress()
            updateCircularProgress(progress: progress)
        }
    }
    
    private func setupCircularTimerContainer() {
        // 设置圆形形状
        timerContainerView.layer.cornerRadius = timerContainerView.bounds.width / 2
        timerContainerView.clipsToBounds = false
        
        // 更新进度环的位置
        let center = CGPoint(x: timerContainerView.bounds.midX, y: timerContainerView.bounds.midY)
        progressBackgroundRingLayer.position = center
        progressRingLayer.position = center
    }
}

