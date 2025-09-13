//
//  BaseViewController.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import UIKit

/// 基础视图控制器，提供通用功能和样式
class BaseViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 加载指示器
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupLoadingIndicator()
    }
    
    // MARK: - Setup Methods
    
    private func setupBaseUI() {
        view.backgroundColor = .systemBackground
        
        // 配置导航栏外观
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    /// 显示加载状态
    func showLoading() {
        DispatchQueue.main.async {
            self.loadingIndicator.startAnimating()
            self.view.isUserInteractionEnabled = false
        }
    }
    
    /// 隐藏加载状态
    func hideLoading() {
        DispatchQueue.main.async {
            self.loadingIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    /// 显示错误提示
    /// - Parameter error: 错误信息
    func showError(_ error: Error) {
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
    
    /// 显示信息提示
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息内容
    ///   - completion: 完成回调
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                completion?()
            })
            
            self.present(alert, animated: true)
        }
    }
}