//
//  BaseViewController.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import UIKit
import Combine
import SnapKit

/// 基础视图控制器，提供通用功能和样式
class BaseViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 错误处理服务
    private let errorHandlingService = ErrorHandlingService()
    
    /// Combine订阅集合
    private var cancellables = Set<AnyCancellable>()
    
    /// 加载指示器
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .primaryBlue
        return indicator
    }()
    
    /// 加载背景视图
    private let loadingBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isHidden = true
        return view
    }()
    
    /// 加载状态标签
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "加载中..."
        label.textColor = .label
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    /// 当前是否正在加载
    private var isLoading = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupLoadingIndicator()
        setupNavigationBarStyle()
        setupErrorHandling()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyThemeConfiguration()
    }
    
    // MARK: - Setup Methods
    
    private func setupBaseUI() {
        view.backgroundColor = .systemBackground
        
        // 添加加载背景视图
        view.addSubview(loadingBackgroundView)
        loadingBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupLoadingIndicator() {
        loadingBackgroundView.addSubview(loadingIndicator)
        loadingBackgroundView.addSubview(loadingLabel)
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        loadingLabel.snp.makeConstraints { make in
            make.top.equalTo(loadingIndicator.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
    }
    
    private func setupNavigationBarStyle() {
        // 配置导航栏外观
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        // 设置导航栏样式
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.tintColor = .primaryBlue
            navigationBar.titleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
            ]
            
            // 配置导航栏背景
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = .clear
            
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    private func setupErrorHandling() {
        // 监听错误状态变化
        errorHandlingService.$currentError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
        
        // 监听优雅降级模式变化
        errorHandlingService.$isInGracefulDegradationMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isInGracefulMode in
                self?.handleGracefulDegradationMode(isInGracefulMode)
            }
            .store(in: &cancellables)
    }
    
    private func applyThemeConfiguration() {
        // 应用主题配置
        view.backgroundColor = .systemBackground
        
        // 更新状态栏样式
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - Loading State Management
    
    /// 显示加载状态
    /// - Parameter message: 加载消息，默认为"加载中..."
    func showLoading(message: String = "加载中...") {
        guard !isLoading else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.loadingLabel.text = message
            self.loadingBackgroundView.isHidden = false
            self.loadingIndicator.startAnimating()
            
            // 添加淡入动画
            self.loadingBackgroundView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.loadingBackgroundView.alpha = 1
            }
        }
    }
    
    /// 隐藏加载状态
    func hideLoading() {
        guard isLoading else { return }
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                self.loadingBackgroundView.alpha = 0
            }) { _ in
                self.isLoading = false
                self.loadingBackgroundView.isHidden = true
                self.loadingIndicator.stopAnimating()
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// 处理HealthyCodeError类型的错误
    /// - Parameter error: HealthyCodeError错误
    private func handleError(_ error: HealthyCodeError) {
        hideLoading()
        
        let title: String
        let message: String
        var actions: [UIAlertAction] = []
        
        switch error {
        case .cameraPermissionDenied:
            title = "摄像头权限"
            message = "需要摄像头权限来检测体态。您可以在设置中启用权限，或选择仅使用计时器功能。"
            
            actions.append(UIAlertAction(title: "设置", style: .default) { _ in
                self.openAppSettings()
            })
            actions.append(UIAlertAction(title: "仅使用计时器", style: .cancel) { _ in
                self.handleGracefulDegradation()
            })
            
        case .cameraNotAvailable:
            title = "摄像头不可用"
            message = "无法访问摄像头。应用将以仅计时器模式运行。"
            actions.append(UIAlertAction(title: "确定", style: .default) { _ in
                self.handleGracefulDegradation()
            })
            
        case .visionFrameworkError(let description):
            title = "视觉处理错误"
            message = "体态检测暂时不可用：\(description)。应用将继续运行其他功能。"
            actions.append(UIAlertAction(title: "确定", style: .default))
            
        case .dataCorruption:
            title = "数据错误"
            message = "检测到数据损坏，正在尝试恢复..."
            actions.append(UIAlertAction(title: "确定", style: .default))
            
        case .sessionInProgress:
            title = "会话进行中"
            message = error.localizedDescription
            actions.append(UIAlertAction(title: "确定", style: .default))
            
        case .invalidSettings:
            title = "设置错误"
            message = error.localizedDescription
            actions.append(UIAlertAction(title: "确定", style: .default))
            
        case .storageError:
            title = "存储错误"
            message = error.localizedDescription
            actions.append(UIAlertAction(title: "重试", style: .default) { _ in
                self.retryLastOperation()
            })
            actions.append(UIAlertAction(title: "确定", style: .cancel))
        }
        
        showAlert(title: title, message: message, actions: actions)
    }
    
    /// 显示通用错误提示
    /// - Parameter error: 错误信息
    func showError(_ error: Error) {
        hideLoading()
        
        if let healthyCodeError = error as? HealthyCodeError {
            handleError(healthyCodeError)
        } else {
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "错误",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    /// 显示信息提示
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息内容
    ///   - completion: 完成回调
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        showAlert(title: title, message: message, actions: [
            UIAlertAction(title: "确定", style: .default) { _ in
                completion?()
            }
        ])
    }
    
    /// 显示带有自定义操作的提示
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息内容
    ///   - actions: 自定义操作数组
    func showAlert(title: String, message: String, actions: [UIAlertAction]) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            
            for action in actions {
                alert.addAction(action)
            }
            
            self.present(alert, animated: true)
        }
    }
    
    /// 显示确认对话框
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息内容
    ///   - confirmTitle: 确认按钮标题
    ///   - cancelTitle: 取消按钮标题
    ///   - confirmAction: 确认操作
    func showConfirmation(
        title: String,
        message: String,
        confirmTitle: String = "确定",
        cancelTitle: String = "取消",
        confirmAction: @escaping () -> Void
    ) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
            alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
                confirmAction()
            })
            
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Graceful Degradation Handling
    
    private func handleGracefulDegradationMode(_ isInGracefulMode: Bool) {
        if isInGracefulMode {
            // 进入优雅降级模式的UI调整
            onEnterGracefulDegradationMode()
        } else {
            // 退出优雅降级模式的UI恢复
            onExitGracefulDegradationMode()
        }
    }
    
    /// 进入优雅降级模式时的处理（子类可重写）
    open func onEnterGracefulDegradationMode() {
        // 子类可以重写此方法来处理特定的UI调整
    }
    
    /// 退出优雅降级模式时的处理（子类可重写）
    open func onExitGracefulDegradationMode() {
        // 子类可以重写此方法来恢复正常UI
    }
    
    private func handleGracefulDegradation() {
        // 通知错误处理服务进入优雅降级模式
        onEnterGracefulDegradationMode()
    }
    
    // MARK: - Utility Methods
    
    /// 打开应用设置
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// 重试上次操作（子类可重写）
    open func retryLastOperation() {
        // 子类可以重写此方法来实现特定的重试逻辑
    }
    
    /// 报告错误到错误处理服务
    /// - Parameters:
    ///   - error: 错误
    ///   - source: 错误源
    func reportError(_ error: HealthyCodeError, source: ErrorSource) {
        errorHandlingService.reportError(error, source: source)
    }
    
    /// 获取错误处理服务
    func getErrorHandlingService() -> ErrorHandlingService {
        return errorHandlingService
    }
    
    // MARK: - Status Bar
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}