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
    
    // 摄像头预览区域
    private let cameraContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    private let cameraPreviewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let cameraPlaceholderView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    private let cameraPlaceholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "camera.fill")
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let cameraPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "摄像头预览"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
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
    
    // 计时器显示区域
    private let timerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        return view
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
    
    private let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .primaryBlue
        progressView.trackTintColor = .systemGray5
        progressView.transform = CGAffineTransform(scaleX: 1, y: 2)
        return progressView
    }()
    
    // 会话信息区域
    private let sessionInfoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.isHidden = true
        return view
    }()
    
    private let sessionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "当前会话"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let sessionStateLabel: UILabel = {
        let label = UILabel()
        label.text = "工作中"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .healthyGreen
        label.textAlignment = .center
        label.backgroundColor = UIColor.healthyGreen.withAlphaComponent(0.2)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        return label
    }()
    
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
        
        // 摄像头预览区域
        contentView.addSubview(cameraContainerView)
        cameraContainerView.addSubview(cameraPreviewView)
        cameraContainerView.addSubview(cameraPlaceholderView)
        cameraPlaceholderView.addSubview(cameraPlaceholderImageView)
        cameraPlaceholderView.addSubview(cameraPlaceholderLabel)
        
        // 体态状态区域
        contentView.addSubview(postureStatusContainerView)
        postureStatusContainerView.addSubview(postureStatusIconView)
        postureStatusContainerView.addSubview(postureStatusLabel)
        postureStatusContainerView.addSubview(postureSubtitleLabel)
        
        // 计时器区域
        contentView.addSubview(timerContainerView)
        timerContainerView.addSubview(timerLabel)
        timerContainerView.addSubview(timerStatusLabel)
        timerContainerView.addSubview(progressView)
        
        // 会话信息区域
        contentView.addSubview(sessionInfoContainerView)
        sessionInfoContainerView.addSubview(sessionTitleLabel)
        sessionInfoContainerView.addSubview(sessionStateLabel)
        sessionInfoContainerView.addSubview(postureWarningView)
        postureWarningView.addSubview(warningIconView)
        postureWarningView.addSubview(warningLabel)
        
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
        
        // 摄像头预览区域约束
        cameraContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(200)
        }
        
        cameraPreviewView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        cameraPlaceholderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        cameraPlaceholderImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-12)
            make.width.height.equalTo(40)
        }
        
        cameraPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalTo(cameraPlaceholderImageView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        // 体态状态区域约束
        postureStatusContainerView.snp.makeConstraints { make in
            make.top.equalTo(cameraContainerView.snp.bottom).offset(16)
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
        
        // 计时器区域约束
        timerContainerView.snp.makeConstraints { make in
            make.top.equalTo(postureStatusContainerView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        timerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }
        
        timerStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(timerLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        progressView.snp.makeConstraints { make in
            make.top.equalTo(timerStatusLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-24)
        }
        
        // 会话信息区域约束
        sessionInfoContainerView.snp.makeConstraints { make in
            make.top.equalTo(timerContainerView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }
        
        sessionTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        
        sessionStateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(sessionTitleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.width.greaterThanOrEqualTo(60)
            make.height.equalTo(24)
        }
        
        postureWarningView.snp.makeConstraints { make in
            make.top.equalTo(sessionTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        warningIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        warningLabel.snp.makeConstraints { make in
            make.leading.equalTo(warningIconView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.top.bottom.equalToSuperview().inset(12)
        }
        
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
        
        // 右侧统计按钮（条件显示）
        updateNavigationBarButtons()
    }
    
    private func setupInitialState() {
        updateCameraPreview()
        updateUI()
    }
    
    // MARK: - UI Update Methods
    
    private func updateUI() {
        guard viewModel != nil else { return }
        updateTimerDisplay()
        updatePostureStatus()
        updateSessionInfo()
        updateControlButtons()
        updateNavigationBarButtons()
    }
    
    private func updateTimerDisplay() {
        guard let viewModel = viewModel else { return }
        
        let timeRemaining = viewModel.timeRemaining
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        // 更新进度
        let progress = viewModel.getSessionProgress()
        progressView.setProgress(Float(progress), animated: true)
        
        // 更新状态标签
        switch viewModel.sessionState {
        case .idle:
            timerStatusLabel.text = "准备开始"
            timerStatusLabel.textColor = .secondaryLabel
        case .running:
            timerStatusLabel.text = "进行中"
            timerStatusLabel.textColor = .primaryBlue
        case .paused:
            timerStatusLabel.text = "已暂停"
            timerStatusLabel.textColor = .warningOrange
        case .completed:
            timerStatusLabel.text = "已完成"
            timerStatusLabel.textColor = .primaryBlue
        case .error:
            timerStatusLabel.text = "错误"
            timerStatusLabel.textColor = .alertRed
        }
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
    
    private func updateSessionInfo() {
        guard let viewModel = viewModel else { return }
        
        let isSessionActive = viewModel.isRunning || viewModel.isPaused
        sessionInfoContainerView.isHidden = !isSessionActive
        
        if isSessionActive {
            sessionStateLabel.text = viewModel.sessionStateDescription
            
            // 更新状态标签颜色
            switch viewModel.sessionState {
            case .running:
                sessionStateLabel.textColor = .healthyGreen
                sessionStateLabel.backgroundColor = UIColor.healthyGreen.withAlphaComponent(0.2)
            case .paused:
                sessionStateLabel.textColor = .warningOrange
                sessionStateLabel.backgroundColor = UIColor.warningOrange.withAlphaComponent(0.2)
            default:
                sessionStateLabel.textColor = .secondaryLabel
                sessionStateLabel.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.2)
            }
            
            // 更新体态警告
            postureWarningView.isHidden = !viewModel.shouldShowPostureWarning()
        }
    }
    
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
    
    private func updateCameraPreview() {
        guard let viewModel = viewModel else { return }
        
        switch viewModel.cameraPermissionStatus {
        case .authorized:
            if let previewLayer = viewModel.postureService.previewLayer {
                setupCameraPreviewLayer(previewLayer)
                cameraPlaceholderView.isHidden = true
            } else {
                cameraPlaceholderView.isHidden = false
            }
        case .denied, .restricted:
            cameraPlaceholderView.isHidden = false
            cameraPlaceholderImageView.tintColor = .alertRed
            cameraPlaceholderLabel.text = "摄像头不可用"
        case .notDetermined:
            cameraPlaceholderView.isHidden = false
            cameraPlaceholderImageView.tintColor = .secondaryLabel
            cameraPlaceholderLabel.text = "点击授权摄像头"
        @unknown default:
            cameraPlaceholderView.isHidden = false
        }
    }
    
    private func setupCameraPreviewLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
        // 移除现有的预览层
        cameraPreviewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // 设置新的预览层
        previewLayer.frame = cameraPreviewView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        cameraPreviewView.layer.addSublayer(previewLayer)
        
        // 确保连接启用
        previewLayer.connection?.isEnabled = true
    }
    
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
        
        // 更新摄像头预览层frame
        if let viewModel = viewModel,
           let previewLayer = viewModel.postureService.previewLayer {
            previewLayer.frame = cameraPreviewView.bounds
        }
    }
}