//
//  WorkSessionViewController.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import UIKit
import SnapKit

/// 主工作会话视图控制器，管理番茄钟和体态检测功能
class WorkSessionViewController: BaseViewController {
    
    // MARK: - Properties
    private let viewModel = WorkSessionViewModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        setupNavigationBar()
        
        print("🚀 WorkSessionViewController: 视图控制器加载完成")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "HealthyCode"
        
        // 创建临时占位内容
        let placeholderLabel = UILabel()
        placeholderLabel.text = "WorkSessionViewController\n准备就绪"
        placeholderLabel.font = .systemFont(ofSize: 18, weight: .medium)
        placeholderLabel.textAlignment = .center
        placeholderLabel.numberOfLines = 0
        placeholderLabel.textColor = .label
        
        view.addSubview(placeholderLabel)
        
        placeholderLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupConstraints() {
        // 约束设置将在后续任务中实现
    }
    
    private func setupBindings() {
        // 数据绑定将在后续任务中实现
    }
    
    private func setupNavigationBar() {
        // 导航栏配置
        navigationItem.largeTitleDisplayMode = .never
    }
}