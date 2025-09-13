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
    
    // MARK: - Camera Properties
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
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
        layer.lineWidth = 6 // 稍微减小线宽，让外侧进度环更精致
        layer.lineCap = .round
        return layer
    }()
    
    private let progressBackgroundRingLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.systemGray5.cgColor
        layer.lineWidth = 6 // 稍微减小线宽，让外侧进度环更精致
        layer.lineCap = .round
        return layer
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.text = "25:00"
        label.font = .monospacedDigitSystemFont(ofSize: 48, weight: .light)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowOpacity = 0.8
        label.layer.shadowRadius = 4
        return label
    }()
    
    private let timerStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "准备开始"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowOpacity = 0.8
        label.layer.shadowRadius = 2
        return label
    }()
    
    // 圆环中心的设置图片
    private let centerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "a1")
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.layer.cornerRadius = 140 // 280/2 = 140，设置为圆形
        imageView.clipsToBounds = true
        // 添加边框以增强视觉效果
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemGray5.cgColor
        return imageView
    }()
    
    // 加载状态指示器
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.layer.shadowColor = UIColor.black.cgColor
        indicator.layer.shadowOffset = CGSize(width: 0, height: 2)
        indicator.layer.shadowOpacity = 0.8
        indicator.layer.shadowRadius = 4
        return indicator
    }()
    
    // 摄像头状态标签
    private let cameraStatusLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.isHidden = true
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowOpacity = 0.8
        label.layer.shadowRadius = 2
        return label
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
        // Use configuration for iOS 15+ or imageEdgeInsets for older versions
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = "开始工作"
            config.image = UIImage(systemName: "play.fill")
            config.imagePadding = 8
            config.baseBackgroundColor = .healthyGreen
            config.baseForegroundColor = .white
            button.configuration = config
        } else {
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        }
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
        setupCameraIntegration()
        
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
        
        // 视图出现时检查是否需要恢复摄像头预览
        if shouldShowCameraPreview() && previewLayer == nil {
            updateCenterImageViewState()
        }
        
        // 注册应用生命周期通知
        registerAppLifecycleNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 视图完全显示后，如果需要摄像头预览且当前没有运行，则启动
        if shouldShowCameraPreview() && !captureSession.isRunning {
            startCameraPreview()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 当视图即将消失时，暂停摄像头预览以节省资源
        // 但不完全停止，以便快速恢复
        pauseCameraSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 视图完全消失后，停止摄像头预览以释放资源
        if captureSession.isRunning {
            stopCameraPreview()
        }
        
        // 注销应用生命周期通知
        unregisterAppLifecycleNotifications()
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
        
        // 添加圆形进度环到timerContainerView的layer（在centerImageView外侧）
        timerContainerView.layer.addSublayer(progressBackgroundRingLayer)
        timerContainerView.layer.addSublayer(progressRingLayer)
        
        timerContainerView.addSubview(centerImageView) // 添加背景图片，在进度环内侧
        timerContainerView.addSubview(timerLabel)      // 再添加文字，确保在上层
        timerContainerView.addSubview(timerStatusLabel)
        timerContainerView.addSubview(loadingIndicator) // 添加加载指示器
        timerContainerView.addSubview(cameraStatusLabel) // 添加摄像头状态标签
        
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
        
        // 计时器区域约束 - 圆形设计，容器需要更大以容纳外侧的进度圆环
        timerContainerView.snp.makeConstraints { make in
            make.top.equalTo(postureStatusContainerView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(320) // 增大容器以容纳外侧进度圆环
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
            make.center.equalToSuperview()
            make.width.height.equalTo(280) // centerImageView保持原来的大小
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        cameraStatusLabel.snp.makeConstraints { make in
            make.bottom.equalTo(centerImageView.snp.bottom).offset(-16)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(80)
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
                // 确保视图控制器仍然存在且视图已加载
                guard let self = self, self.isViewLoaded else { return }
                self.updateUI()
            }
            .store(in: &cancellables)
        
        // 监听错误状态
        viewModel.$showingError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showingError in
                guard let self = self, self.isViewLoaded else { return }
                if showingError, let errorMessage = self.viewModel.errorMessage {
                    self.showAlert(title: "错误", message: errorMessage)
                }
            }
            .store(in: &cancellables)
        
        // 监听会话状态变化以同步摄像头状态
        viewModel.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionState in
                guard let self = self, self.isViewLoaded else { return }
                self.handleSessionStateChange(sessionState)
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
    
    private func setupCameraIntegration() {
        print("📷 开始设置摄像头集成")
        checkPermissionAndSetup()
        setupCameraNotifications()
    }
    
    private func setupCameraNotifications() {
        // 监听摄像头会话中断通知
        if #available(iOS 18.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(cameraSessionWasInterrupted(_:)),
                name: AVCaptureSession.wasInterruptedNotification,
                object: captureSession
            )
            
            // 监听摄像头会话中断结束通知
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(cameraSessionInterruptionEnded(_:)),
                name: AVCaptureSession.interruptionEndedNotification,
                object: captureSession
            )
            
            // 监听摄像头会话运行时错误通知
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(cameraSessionRuntimeError(_:)),
                name: AVCaptureSession.runtimeErrorNotification,
                object: captureSession
            )
        } else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(cameraSessionWasInterrupted(_:)),
                name: .AVCaptureSessionWasInterrupted,
                object: captureSession
            )
            
            // 监听摄像头会话中断结束通知
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(cameraSessionInterruptionEnded(_:)),
                name: .AVCaptureSessionInterruptionEnded,
                object: captureSession
            )
            
            // 监听摄像头会话运行时错误通知
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(cameraSessionRuntimeError(_:)),
                name: .AVCaptureSessionRuntimeError,
                object: captureSession
            )
        }
    }
    
    // MARK: - App Lifecycle Management
    
    private func registerAppLifecycleNotifications() {
        // 监听应用进入后台通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 监听应用即将进入前台通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // 监听应用变为活跃状态通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // 监听应用即将失去活跃状态通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // 监听内存警告通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarningNotification),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    private func unregisterAppLifecycleNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    // MARK: - App Lifecycle Handlers
    
    @objc private func appDidEnterBackground() {
        print("📱 应用进入后台 - 暂停摄像头会话")
        
        // 应用进入后台时暂停摄像头会话以节省电池和资源
        pauseCameraSession()
        
        // 移除动画以节省资源
        removePulseAnimation()
        
        // 显示状态消息
        showCameraStatusMessage("应用已进入后台", isError: false)
    }
    
    @objc private func appWillEnterForeground() {
        print("📱 应用即将进入前台 - 准备恢复摄像头会话")
        
        // 应用即将进入前台时准备恢复摄像头会话
        // 但不立即启动，等待应用完全激活
        showCameraStatusMessage("正在恢复摄像头...", isError: false)
    }
    
    @objc private func appDidBecomeActive() {
        print("📱 应用变为活跃状态 - 恢复摄像头会话")
        
        // 应用变为活跃状态时恢复摄像头会话
        if shouldShowCameraPreview() {
            // 延迟一点时间以确保UI完全准备好
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.resumeCameraSession()
            }
        }
        
        // 2秒后隐藏状态消息
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.hideCameraStatusMessage()
        }
    }
    
    @objc private func appWillResignActive() {
        print("📱 应用即将失去活跃状态 - 暂停摄像头会话")
        
        // 应用即将失去活跃状态时暂停摄像头会话
        // 这可能是由于来电、控制中心等临时中断
        pauseCameraSession()
    }
    

    
    // MARK: - Memory Management
    
    private func handleMemoryWarning() {
        // 停止摄像头预览以释放内存
        if captureSession.isRunning {
            print("⚠️ 内存警告：停止摄像头会话")
            stopCameraPreview()
            
            // 显示内存警告状态
            showCameraStatusMessage("内存不足，已暂停摄像头", isError: true)
            
            // 5秒后尝试恢复（如果内存情况改善）
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                guard let self = self else { return }
                
                if self.shouldShowCameraPreview() {
                    print("⚠️ 内存警告后尝试恢复摄像头")
                    self.startCameraPreview()
                    self.showCameraStatusMessage("摄像头已恢复", isError: false)
                    
                    // 2秒后隐藏状态消息
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.hideCameraStatusMessage()
                    }
                }
            }
        }
        
        // 移除所有动画以节省内存
        removePulseAnimation()
        centerImageView.layer.removeAllAnimations()
        
        // 清理不必要的缓存
        if let previewLayer = previewLayer, !shouldShowCameraPreview() {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
            print("⚠️ 内存警告：移除预览层")
        }
    }
    
    @objc private func cameraSessionWasInterrupted(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonIntegerValue = userInfo[AVCaptureSessionInterruptionReasonKey] as? Int,
              let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) else {
            return
        }
        
        print("📷 摄像头会话被中断: \(reason)")
        
        DispatchQueue.main.async { [weak self] in
            switch reason {
            case .videoDeviceNotAvailableInBackground:
                self?.showCameraStatusMessage("应用进入后台", isError: false)
            case .audioDeviceInUseByAnotherClient, .videoDeviceInUseByAnotherClient:
                self?.showCameraStatusMessage("摄像头被其他应用占用", isError: true)
            case .videoDeviceNotAvailableWithMultipleForegroundApps:
                self?.showCameraStatusMessage("多应用模式下摄像头不可用", isError: true)
            case .videoDeviceNotAvailableDueToSystemPressure:
                self?.showCameraStatusMessage("系统压力过大，摄像头暂停", isError: true)
            case .sensitiveContentMitigationActivated:
                self?.showCameraStatusMessage("敏感内容缓解已激活", isError: true)
            @unknown default:
                self?.showCameraStatusMessage("摄像头会话中断", isError: true)
            }
            
            // 移除脉冲动画
            self?.removePulseAnimation()
        }
    }
    
    @objc private func cameraSessionInterruptionEnded(_ notification: Notification) {
        print("📷 摄像头会话中断结束")
        
        DispatchQueue.main.async { [weak self] in
            self?.showCameraStatusMessage("摄像头已恢复", isError: false)
            
            // 如果应该显示摄像头预览，重新添加脉冲动画
            if self?.shouldShowCameraPreview() == true {
                self?.addPulseAnimation()
            }
            
            // 2秒后隐藏状态消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self?.hideCameraStatusMessage()
            }
        }
    }
    
    @objc private func cameraSessionRuntimeError(_ notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else {
            return
        }
        
        print("📷 摄像头会话运行时错误: \(error)")
        
        DispatchQueue.main.async { [weak self] in
            self?.showCameraStatusMessage("摄像头错误: \(error.localizedDescription)", isError: true)
            self?.removePulseAnimation()
            
            // 尝试重新启动会话
            if error.code == .mediaServicesWereReset {
                self?.sessionQueue.async { [weak self] in
                    guard let self = self else { return }
                    if self.shouldShowCameraPreview() {
                        self.captureSession.startRunning()
                    }
                }
            }
        }
    }
    
    @MainActor
    deinit {
        print("🗑️ WorkSessionViewController: 开始释放资源")
        
        // 停止摄像头会话
        sessionQueue.async { [captureSession] in
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
        
        // 移除预览层
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        
        // 移除所有动画
        centerImageView.layer.removeAllAnimations()
        
        // 取消所有Combine订阅
        cancellables.removeAll()
        
        // 移除所有通知观察者
        NotificationCenter.default.removeObserver(self)
        
        print("🗑️ WorkSessionViewController: 资源释放完成")
    }
    
    // MARK: - UI Update Methods
    
    private func updateUI() {
        guard viewModel != nil else { return }
        updateTimerDisplay()
        updatePostureStatus()
        updateControlButtons()
        updateNavigationBarButtons()
        updateCenterImageViewState()
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
            timerStatusLabel.textColor = .white
            progressRingLayer.strokeColor = UIColor.systemGray4.cgColor
        case .running:
            timerStatusLabel.text = "进行中"
            timerStatusLabel.textColor = .white
            progressRingLayer.strokeColor = UIColor.primaryBlue.cgColor
        case .paused:
            timerStatusLabel.text = "已暂停"
            timerStatusLabel.textColor = .white
            progressRingLayer.strokeColor = UIColor.warningOrange.cgColor
        case .completed:
            timerStatusLabel.text = "已完成"
            timerStatusLabel.textColor = .white
            progressRingLayer.strokeColor = UIColor.healthyGreen.cgColor
        case .error:
            timerStatusLabel.text = "错误"
            timerStatusLabel.textColor = .white
            progressRingLayer.strokeColor = UIColor.alertRed.cgColor
        }
    }
    
    private func updateCircularProgress(progress: Double) {
        // 使用 timerContainerView 的坐标系，中心点为 bounds 的中心
        let containerBounds = timerContainerView.bounds
        let center = CGPoint(x: containerBounds.midX, y: containerBounds.midY)
        
        // 进度圆环的半径应该比centerImageView稍大，在其外侧
        // centerImageView的半径是140，所以进度圆环的半径设为150
        let radius: CGFloat = 150
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
        case .notPresent:
            iconName = "person.slash.fill"
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
            // 重置后切换回静态图片
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateCenterImageViewState()
            }
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
                // 启动会话后立即切换到摄像头预览
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateCenterImageViewState()
                }
            }
        case .running:
            viewModel.pauseSession()
            // 暂停时保持摄像头预览，不需要切换状态
        case .paused:
            viewModel.resumeSession()
            // 恢复时保持摄像头预览，不需要切换状态
        case .error:
            viewModel.resetSession()
            // 重置时切换回静态图片
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateCenterImageViewState()
            }
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
        
        // 更新摄像头预览层的frame以匹配centerImageView
        if let previewLayer = previewLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = centerImageView.bounds
            previewLayer.cornerRadius = centerImageView.layer.cornerRadius
            CATransaction.commit()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("⚠️ 视图控制器收到内存警告")
        
        // 调用内存警告处理方法
        handleMemoryWarning()
    }
    
    @objc private func didReceiveMemoryWarningNotification() {
        print("⚠️ 收到内存警告通知 - 释放摄像头资源")
        
        // 收到内存警告时释放摄像头资源
        handleMemoryWarning()
    }
    
    private func setupCircularTimerContainer() {
        // 设置圆形形状
        timerContainerView.layer.cornerRadius = timerContainerView.bounds.width / 2
        timerContainerView.clipsToBounds = false
        
        // 设置进度环的 bounds 和 position
        let containerBounds = timerContainerView.bounds
        progressBackgroundRingLayer.bounds = containerBounds
        progressRingLayer.bounds = containerBounds
        progressBackgroundRingLayer.position = CGPoint(x: containerBounds.midX, y: containerBounds.midY)
        progressRingLayer.position = CGPoint(x: containerBounds.midX, y: containerBounds.midY)
    }
    
    // MARK: - Camera Integration Methods
    
    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCameraSession()
                    }
                    // Update UI regardless of permission result
                    self?.updateUI()
                }
            }
        case .denied, .restricted:
            // Permission denied or restricted - will show static image
            print("📷 摄像头权限被拒绝或受限")
        @unknown default:
            print("📷 未知的摄像头权限状态")
        }
    }
    
    private func setupCameraSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            // 设置会话预设为高质量
            if self.captureSession.canSetSessionPreset(.high) {
                self.captureSession.sessionPreset = .high
            } else {
                self.captureSession.sessionPreset = .photo
            }
            
            // 找到前置摄像头
            let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInTrueDepthCamera, .builtInWideAngleCamera]
            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: .front
            )
            
            guard let frontDevice = discovery.devices.first else {
                print("📷 找不到前置摄像头")
                DispatchQueue.main.async { [weak self] in
                    self?.showCameraStatusMessage("找不到前置摄像头", isError: true)
                }
                self.captureSession.commitConfiguration()
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: frontDevice)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    
                    // 配置摄像头设备属性以获得更好的视觉效果
                    try frontDevice.lockForConfiguration()
                    
                    // 设置自动对焦模式
                    if frontDevice.isFocusModeSupported(.continuousAutoFocus) {
                        frontDevice.focusMode = .continuousAutoFocus
                    }
                    
                    // 设置自动曝光模式
                    if frontDevice.isExposureModeSupported(.continuousAutoExposure) {
                        frontDevice.exposureMode = .continuousAutoExposure
                    }
                    
                    // 设置自动白平衡
                    if frontDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                        frontDevice.whiteBalanceMode = .continuousAutoWhiteBalance
                    }
                    
                    frontDevice.unlockForConfiguration()
                }
            } catch {
                print("📷 创建摄像头输入失败：", error)
                DispatchQueue.main.async { [weak self] in
                    self?.showCameraStatusMessage("摄像头初始化失败", isError: true)
                }
                self.captureSession.commitConfiguration()
                return
            }
            
            self.captureSession.commitConfiguration()
            print("📷 摄像头会话设置完成")
        }
    }
    
    private func startCameraPreview() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            print("📷 摄像头权限未授权，无法启动预览")
            showCameraStatusMessage("摄像头权限未授权", isError: true)
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                print("📷 摄像头预览已启动")
                
                DispatchQueue.main.async {
                    // 添加脉冲动画表示摄像头激活
                    self.addPulseAnimation()
                }
            }
        }
    }
    
    private func stopCameraPreview() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("📷 摄像头预览已停止")
                
                DispatchQueue.main.async {
                    // 移除脉冲动画
                    self.removePulseAnimation()
                    self.transitionToStaticImage()
                }
            }
        }
    }
    
    private func pauseCameraSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("📷 摄像头会话已暂停")
                
                DispatchQueue.main.async {
                    // 移除脉冲动画但保持预览层
                    self.removePulseAnimation()
                }
            }
        }
    }
    
    private func resumeCameraSession() {
        guard shouldShowCameraPreview() else {
            print("📷 不需要恢复摄像头会话")
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                print("📷 摄像头会话已恢复")
                
                DispatchQueue.main.async {
                    // 恢复脉冲动画
                    if self.previewLayer != nil {
                        self.addPulseAnimation()
                    }
                }
            }
        }
    }
    
    private func setupCameraPreviewLayer() {
        guard previewLayer == nil else {
            print("📷 预览层已存在，跳过设置")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard let previewLayer = previewLayer else {
            print("📷 创建预览层失败")
            showCameraStatusMessage("摄像头初始化失败", isError: true)
            return
        }
        
        // 设置预览层属性
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = centerImageView.bounds
        
        // 设置视频方向 - 确保正确的方向显示
        if let connection = previewLayer.connection {
            if #available(iOS 17.0, *) {
                // 使用新的旋转角度API
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90 // 向左旋转90度以匹配CameraTestViewController
                }
            } else {
                // 使用旧的视频方向API
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .landscapeRight // 向左旋转90度
                }
            }
        }
        
        // 确保圆形裁剪效果和边框
        previewLayer.cornerRadius = centerImageView.layer.cornerRadius
        previewLayer.masksToBounds = true
        
        // 添加预览层到centerImageView的最底层
        centerImageView.layer.insertSublayer(previewLayer, at: 0)
        
        // 更新边框颜色以指示摄像头激活状态
//        updateCenterImageViewBorder(isActive: true)
        
        print("📷 摄像头预览层设置完成")
    }
    
    private func transitionToCamera() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            print("📷 摄像头权限未授权，无法切换到摄像头预览")
            showCameraStatusMessage("摄像头权限未授权", isError: true)
            return
        }
        
        print("📷 开始切换到摄像头预览")
        
        // 显示加载状态
        showLoadingState(true)
        showCameraStatusMessage("正在启动摄像头...", isError: false)
        
        // 启动摄像头预览
        startCameraPreview()
        
        // 延迟执行切换动画，给摄像头启动一些时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // 执行平滑的切换动画
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseInOut]) {
                // 缩放效果
                self.centerImageView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            } completion: { _ in
                UIView.transition(with: self.centerImageView, duration: 0.6, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                    // 隐藏静态图片，显示摄像头预览
                    self.centerImageView.image = nil
                    self.setupCameraPreviewLayer()
                } completion: { _ in
                    UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3) {
                        // 恢复正常大小
                        self.centerImageView.transform = .identity
                    } completion: { _ in
                        self.showLoadingState(false)
                        self.showCameraStatusMessage("摄像头已激活", isError: false)
                        
                        // 2秒后隐藏状态消息
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.hideCameraStatusMessage()
                        }
                        
                        print("📷 切换到摄像头预览完成")
                    }
                }
            }
        }
    }
    
    private func transitionToStaticImage() {
        print("📷 开始切换到静态图片")
        
        // 显示加载状态
        showLoadingState(true)
        showCameraStatusMessage("正在停止摄像头...", isError: false)
        
        // 执行平滑的切换动画
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseInOut]) {
            // 轻微缩放效果
            self.centerImageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.transition(with: self.centerImageView, duration: 0.5, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                // 移除预览层
                self.previewLayer?.removeFromSuperlayer()
                self.previewLayer = nil
                
                // 恢复静态图片
                self.centerImageView.image = UIImage(named: "a1")
                
                // 更新边框颜色
                self.updateCenterImageViewBorder(isActive: false)
            } completion: { _ in
                UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3) {
                    // 恢复正常大小
                    self.centerImageView.transform = .identity
                } completion: { _ in
                    self.showLoadingState(false)
                    self.hideCameraStatusMessage()
                    print("📷 切换到静态图片完成")
                }
            }
        }
    }
    
    // MARK: - Session State Management
    
    private func handleSessionStateChange(_ sessionState: WorkSessionViewModel.SessionState) {
        print("📷 会话状态变化: \(sessionState)")
        
        // 根据会话状态变化更新摄像头状态
        switch sessionState {
        case .running:
            // 会话开始时启动摄像头预览
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.updateCenterImageViewState()
            }
        case .idle, .completed:
            // 会话结束或重置时停止摄像头预览
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateCenterImageViewState()
            }
        case .paused:
            // 暂停时保持摄像头预览状态
            break
        case .error:
            // 错误状态时停止摄像头预览
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateCenterImageViewState()
            }
        }
    }
    
    // MARK: - Camera State Management
    
    private func shouldShowCameraPreview() -> Bool {
        guard let viewModel = viewModel else { return false }
        
        // 只有在会话运行时且有摄像头权限时才显示摄像头预览
        let hasPermission = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        let isSessionActive = viewModel.sessionState == .running || viewModel.sessionState == .paused
        
        return hasPermission && isSessionActive
    }
    
    private func updateCenterImageViewState() {
        guard let viewModel = viewModel else { return }
        
        print("📷 更新centerImageView状态 - 会话状态: \(viewModel.sessionState), 权限状态: \(AVCaptureDevice.authorizationStatus(for: .video).rawValue)")
        
        if shouldShowCameraPreview() {
            // 如果当前没有显示摄像头预览，则切换到摄像头预览
            if previewLayer == nil {
                print("📷 切换到摄像头预览模式")
                transitionToCamera()
            } else {
                print("📷 摄像头预览已激活，保持当前状态")
            }
        } else {
            // 如果当前显示摄像头预览，则切换到静态图片
            if previewLayer != nil {
                print("📷 切换到静态图片模式")
                stopCameraPreview()
            } else {
                print("📷 静态图片已显示，保持当前状态")
            }
        }
    }
    
    // MARK: - Visual Effects Helper Methods
    
    private func showLoadingState(_ show: Bool) {
        DispatchQueue.main.async { [weak self] in
            if show {
                self?.loadingIndicator.startAnimating()
            } else {
                self?.loadingIndicator.stopAnimating()
            }
        }
    }
    
    private func showCameraStatusMessage(_ message: String, isError: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.cameraStatusLabel.text = "  \(message)  "
            self.cameraStatusLabel.backgroundColor = isError ? 
                UIColor.alertRed.withAlphaComponent(0.8) : 
                UIColor.black.withAlphaComponent(0.7)
            
            // 显示动画
            self.cameraStatusLabel.isHidden = false
            self.cameraStatusLabel.alpha = 0
            self.cameraStatusLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.cameraStatusLabel.alpha = 1
                self.cameraStatusLabel.transform = .identity
            }
        }
    }
    
    private func hideCameraStatusMessage() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.cameraStatusLabel.alpha = 0
                self.cameraStatusLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            } completion: { _ in
                self.cameraStatusLabel.isHidden = true
                self.cameraStatusLabel.transform = .identity
            }
        }
    }
    
    private func updateCenterImageViewBorder(isActive: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let borderColor = isActive ? UIColor.primaryBlue.cgColor : UIColor.systemGray5.cgColor
            let borderWidth: CGFloat = isActive ? 4 : 3
            
            UIView.animate(withDuration: 0.3) {
                self.centerImageView.layer.borderColor = borderColor
                self.centerImageView.layer.borderWidth = borderWidth
            }
        }
    }
    
    private func addPulseAnimation() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 移除现有动画
            self.centerImageView.layer.removeAnimation(forKey: "pulse")
            
            // 创建脉冲动画
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = 2.0
            pulseAnimation.fromValue = 1.0
            pulseAnimation.toValue = 1.02
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .infinity
            
            self.centerImageView.layer.add(pulseAnimation, forKey: "pulse")
        }
    }
    
    private func removePulseAnimation() {
        DispatchQueue.main.async { [weak self] in
            self?.centerImageView.layer.removeAnimation(forKey: "pulse")
        }
    }
}
