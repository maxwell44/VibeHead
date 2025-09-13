//
//  UIKitCameraPreviewView.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import UIKit
import AVFoundation
import SnapKit
import Combine

/// UIKit版本的摄像头预览组件
/// 使用AVCaptureVideoPreviewLayer显示摄像头预览，处理权限状态和错误情况
class UIKitCameraPreviewView: UIView {
    
    // MARK: - Properties
    
    /// 摄像头会话
    private let captureSession = AVCaptureSession()
    
    /// 会话队列
    private let sessionQueue = DispatchQueue(label: "camera.preview.session.queue")
    
    /// 当前权限状态
    private var authorizationStatus: AVAuthorizationStatus = .notDetermined {
        didSet {
            DispatchQueue.main.async {
                self.updateUI()
            }
        }
    }
    
    /// 是否正在显示预览
    private var isPreviewActive: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.updateUI()
            }
        }
    }
    
    /// 当前错误状态
    private var currentError: HealthyCodeError? {
        didSet {
            DispatchQueue.main.async {
                self.updateUI()
            }
        }
    }
    
    // MARK: - UI Components
    
    /// 主容器视图
    private let containerView = UIView()
    
    /// 预览容器视图 - 用于包含AVCaptureVideoPreviewLayer
    private let previewContainerView = UIView()
    
    /// 摄像头预览层
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    /// 占位符视图 - 当摄像头不可用时显示
    private let placeholderView = UIView()
    
    /// 占位符图标
    private let placeholderIconView = UIImageView()
    
    /// 占位符标题标签
    private let placeholderTitleLabel = UILabel()
    
    /// 占位符描述标签
    private let placeholderDescriptionLabel = UILabel()
    
    /// 权限请求按钮
    private let permissionButton = UIButton(type: .system)
    
    /// 状态指示器
    private let statusIndicatorView = UIView()
    
    /// 状态指示器图标
    private let statusIconView = UIImageView()
    
    /// 加载指示器
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Callbacks
    
    /// 权限请求回调
    var onPermissionRequested: (() -> Void)?
    
    /// 设置按钮点击回调
    var onSettingsRequested: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupNotifications()
        updateUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        setupNotifications()
        updateUI()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        // 当视图被添加到父视图时，自动启动预览
        if superview != nil {
            startPreview()
        }
    }
    

    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 配置主容器视图
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        containerView.clipsToBounds = true
        
        // 配置预览容器视图
        previewContainerView.backgroundColor = .black
        previewContainerView.layer.cornerRadius = 12
        previewContainerView.clipsToBounds = true
        
        // 配置占位符视图
        placeholderView.backgroundColor = .systemGray6
        placeholderView.isHidden = false
        
        // 配置占位符图标
        placeholderIconView.image = UIImage(systemName: "camera.fill")
        placeholderIconView.contentMode = .scaleAspectFit
        placeholderIconView.tintColor = .systemGray3
        
        // 配置占位符标题标签
        placeholderTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        placeholderTitleLabel.textAlignment = .center
        placeholderTitleLabel.textColor = .label
        placeholderTitleLabel.text = "摄像头预览"
        
        // 配置占位符描述标签
        placeholderDescriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        placeholderDescriptionLabel.textAlignment = .center
        placeholderDescriptionLabel.textColor = .secondaryLabel
        placeholderDescriptionLabel.numberOfLines = 0
        placeholderDescriptionLabel.text = "需要摄像头权限来检测体态"
        
        // 配置权限请求按钮
        permissionButton.setTitle("请求权限", for: .normal)
        permissionButton.setTitleColor(.white, for: .normal)
        permissionButton.backgroundColor = .primaryBlue
        permissionButton.layer.cornerRadius = 8
        permissionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        permissionButton.addTarget(self, action: #selector(permissionButtonTapped), for: .touchUpInside)
        
        // 配置状态指示器
        statusIndicatorView.backgroundColor = .systemBackground
        statusIndicatorView.layer.cornerRadius = 16
        statusIndicatorView.layer.shadowColor = UIColor.black.cgColor
        statusIndicatorView.layer.shadowOpacity = 0.1
        statusIndicatorView.layer.shadowOffset = CGSize(width: 0, height: 2)
        statusIndicatorView.layer.shadowRadius = 4
        
        // 配置状态图标
        statusIconView.contentMode = .scaleAspectFit
        statusIconView.tintColor = .healthyGreen
        
        // 配置加载指示器
        loadingIndicator.hidesWhenStopped = true
        
        // 添加子视图
        addSubview(containerView)
        containerView.addSubview(previewContainerView)
        containerView.addSubview(placeholderView)
        
        placeholderView.addSubview(placeholderIconView)
        placeholderView.addSubview(placeholderTitleLabel)
        placeholderView.addSubview(placeholderDescriptionLabel)
        placeholderView.addSubview(permissionButton)
        
        containerView.addSubview(statusIndicatorView)
        statusIndicatorView.addSubview(statusIconView)
        statusIndicatorView.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        // 主容器约束
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(200) // 固定高度，匹配设计要求
        }
        
        // 预览容器约束
        previewContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        // 占位符视图约束
        placeholderView.snp.makeConstraints { make in
            make.edges.equalTo(previewContainerView)
        }
        
        // 占位符图标约束
        placeholderIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.width.height.equalTo(48)
        }
        
        // 占位符标题约束
        placeholderTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(placeholderIconView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        // 占位符描述约束
        placeholderDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(placeholderTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        // 权限按钮约束
        permissionButton.snp.makeConstraints { make in
            make.top.equalTo(placeholderDescriptionLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(36)
        }
        
        // 状态指示器约束
        statusIndicatorView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.width.height.equalTo(32)
        }
        
        // 状态图标约束
        statusIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        // 加载指示器约束
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCameraError(_:)),
            name: .cameraErrorOccurred,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// 开始预览
    func startPreview() {
        checkPermissionAndSetup()
    }
    
    /// 停止预览
    func stopPreview() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
        
        DispatchQueue.main.async {
            self.isPreviewActive = false
        }
    }
    
    // MARK: - Private Methods
    
    private var cancellables = Set<AnyCancellable>()
    
    /// 检查权限并设置摄像头
    private func checkPermissionAndSetup() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus {
        case .authorized:
            setupCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self?.setupCameraSession()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedState()
        @unknown default:
            showErrorState(.cameraNotAvailable)
        }
    }
    
    /// 设置摄像头会话
    private func setupCameraSession() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .medium
            
            // 找到前置摄像头
            let deviceTypes: [AVCaptureDevice.DeviceType] = [
                .builtInWideAngleCamera,
                .builtInTrueDepthCamera
            ]
            
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: .front
            )
            
            guard let frontCamera = discoverySession.devices.first else {
                print("🎥 找不到前置摄像头")
                DispatchQueue.main.async {
                    self.showErrorState(.cameraNotAvailable)
                }
                self.captureSession.commitConfiguration()
                return
            }
            
            do {
                // 创建输入
                let input = try AVCaptureDeviceInput(device: frontCamera)
                
                // 移除现有输入
                for existingInput in self.captureSession.inputs {
                    self.captureSession.removeInput(existingInput)
                }
                
                // 添加新输入
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    print("🎥 ✅ 摄像头输入添加成功")
                } else {
                    throw HealthyCodeError.cameraNotAvailable
                }
                
                self.captureSession.commitConfiguration()
                
                // 在主线程设置预览层
                DispatchQueue.main.async {
                    self.setupPreviewLayer()
                }
                
                // 启动会话
                self.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isPreviewActive = self.captureSession.isRunning
                    print("🎥 摄像头会话启动: \(self.isPreviewActive)")
                }
                
            } catch {
                print("🎥 ❌ 创建摄像头输入失败: \(error)")
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    self.showErrorState(.cameraNotAvailable)
                }
            }
        }
    }
    
    /// 设置预览层
    private func setupPreviewLayer() {
        // 移除旧的预览层
        previewLayer?.removeFromSuperlayer()
        
        // 创建新的预览层
        let newPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        newPreviewLayer.videoGravity = .resizeAspectFill
        newPreviewLayer.frame = previewContainerView.bounds
        
        // 设置视频方向 (使用新的 API)
        if let connection = newPreviewLayer.connection {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(0) {
                    connection.videoRotationAngle = 0
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }
        
        // 添加到预览容器
        previewContainerView.layer.insertSublayer(newPreviewLayer, at: 0)
        previewLayer = newPreviewLayer
        
        print("🎥 ✅ 预览层设置完成")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 更新预览层大小
        if let previewLayer = previewLayer {
            previewLayer.frame = previewContainerView.bounds
            print("🎥 更新预览层大小: \(previewContainerView.bounds)")
        }
    }
    
    private func updateUI() {
        updatePlaceholderState()
        updateStatusIndicator()
        updateContainerAppearance()
    }
    
    private func updatePlaceholderState() {
        let shouldShowPlaceholder = !isPreviewActive || authorizationStatus != .authorized
        
        print("🎥 更新占位符状态: shouldShow=\(shouldShowPlaceholder), isPreviewActive=\(isPreviewActive), authStatus=\(authorizationStatus)")
        
        UIView.animate(withDuration: 0.3) {
            self.placeholderView.isHidden = !shouldShowPlaceholder
            // 当预览激活时，确保预览容器完全可见
            self.previewContainerView.alpha = (shouldShowPlaceholder && !self.isPreviewActive) ? 0.3 : 1.0
        }
        
        // 更新占位符内容
        switch authorizationStatus {
        case .notDetermined:
            updatePlaceholderContent(
                icon: "camera.fill",
                title: "摄像头预览",
                description: "需要摄像头权限来检测体态",
                buttonTitle: "请求权限",
                showButton: true
            )
        case .denied, .restricted:
            updatePlaceholderContent(
                icon: "camera.fill.badge.xmark",
                title: "摄像头权限被拒绝",
                description: "请在设置中允许摄像头权限，或使用仅计时器模式",
                buttonTitle: "打开设置",
                showButton: true
            )
        case .authorized:
            if !isPreviewActive {
                updatePlaceholderContent(
                    icon: "camera.fill",
                    title: "正在启动摄像头",
                    description: "请稍候...",
                    buttonTitle: "",
                    showButton: false
                )
            }
        @unknown default:
            updatePlaceholderContent(
                icon: "exclamationmark.triangle.fill",
                title: "摄像头不可用",
                description: "请检查摄像头是否被其他应用占用",
                buttonTitle: "重试",
                showButton: true
            )
        }
        
        // 处理错误状态
        if let error = currentError {
            updatePlaceholderForError(error)
        }
    }
    
    private func updatePlaceholderContent(
        icon: String,
        title: String,
        description: String,
        buttonTitle: String,
        showButton: Bool
    ) {
        placeholderIconView.image = UIImage(systemName: icon)
        placeholderTitleLabel.text = title
        placeholderDescriptionLabel.text = description
        permissionButton.setTitle(buttonTitle, for: .normal)
        permissionButton.isHidden = !showButton
        
        // 更新图标颜色
        switch authorizationStatus {
        case .denied, .restricted:
            placeholderIconView.tintColor = .alertRed
        case .authorized:
            placeholderIconView.tintColor = .systemGray3
        default:
            placeholderIconView.tintColor = .systemGray3
        }
    }
    
    private func updatePlaceholderForError(_ error: HealthyCodeError) {
        switch error {
        case .cameraPermissionDenied:
            updatePlaceholderContent(
                icon: "camera.fill.badge.xmark",
                title: "摄像头权限被拒绝",
                description: error.recoverySuggestion ?? "请在设置中允许摄像头权限",
                buttonTitle: "打开设置",
                showButton: true
            )
        case .cameraNotAvailable:
            updatePlaceholderContent(
                icon: "camera.fill.badge.xmark",
                title: "摄像头不可用",
                description: error.recoverySuggestion ?? "请检查摄像头是否被其他应用占用",
                buttonTitle: "重试",
                showButton: true
            )
        default:
            updatePlaceholderContent(
                icon: "exclamationmark.triangle.fill",
                title: "发生错误",
                description: error.localizedDescription,
                buttonTitle: "重试",
                showButton: true
            )
        }
        
        placeholderIconView.tintColor = .alertRed
    }
    
    private func updateStatusIndicator() {
        let (icon, color, showLoading) = getStatusIndicatorInfo()
        
        UIView.animate(withDuration: 0.3) {
            self.statusIconView.image = UIImage(systemName: icon)
            self.statusIconView.tintColor = color
            self.statusIconView.isHidden = showLoading
        }
        
        if showLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
    
    private func getStatusIndicatorInfo() -> (String, UIColor, Bool) {
        if currentError != nil {
            return ("exclamationmark.triangle.fill", .alertRed, false)
        }
        
        switch authorizationStatus {
        case .authorized:
            if isPreviewActive {
                return ("checkmark.circle.fill", .healthyGreen, false)
            } else {
                return ("", .clear, true) // 显示加载指示器
            }
        case .denied, .restricted:
            return ("xmark.circle.fill", .alertRed, false)
        case .notDetermined:
            return ("questionmark.circle.fill", .warningOrange, false)
        @unknown default:
            return ("exclamationmark.triangle.fill", .alertRed, false)
        }
    }
    
    private func updateContainerAppearance() {
        let borderColor: UIColor
        
        if let _ = currentError {
            borderColor = .alertRed
        } else {
            switch authorizationStatus {
            case .authorized:
                borderColor = isPreviewActive ? .healthyGreen : .systemGray4
            case .denied, .restricted:
                borderColor = .alertRed
            default:
                borderColor = .systemGray4
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.containerView.layer.borderColor = borderColor.cgColor
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.authorizationStatus = .authorized
                    self?.setupCameraSession()
                } else {
                    self?.authorizationStatus = .denied
                    self?.showPermissionDeniedState()
                }
            }
        }
    }
    
    private func showPermissionDeniedState() {
        currentError = .cameraPermissionDenied
    }
    
    private func showErrorState(_ error: HealthyCodeError) {
        currentError = error
    }
    
    // MARK: - Actions
    
    @objc private func permissionButtonTapped() {
        switch authorizationStatus {
        case .notDetermined:
            onPermissionRequested?()
            requestCameraPermission()
        case .denied, .restricted:
            onSettingsRequested?()
            openAppSettings()
        default:
            // 重试操作
            currentError = nil
            startPreview()
        }
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        
        UIApplication.shared.open(settingsUrl)
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleCameraError(_ notification: Notification) {
        guard let error = notification.object as? HealthyCodeError else { return }
        showErrorState(error)
    }
    
    @objc private func applicationDidBecomeActive() {
        // 应用重新激活时检查权限状态
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    deinit {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

// MARK: - Combine Support

import Combine

extension UIKitCameraPreviewView {
    // Combine cancellables storage is already defined above
}