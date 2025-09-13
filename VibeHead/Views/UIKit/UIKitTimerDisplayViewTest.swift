//
//  UIKitTimerDisplayViewTest.swift
//  VibeHead
//
//  Test file for UIKitTimerDisplayView to verify functionality
//

import UIKit
import SnapKit

/// 测试视图控制器，用于验证UIKitTimerDisplayView的功能
class UIKitTimerDisplayViewTestController: UIViewController {
    
    private let timerDisplayView = UIKitTimerDisplayView()
    private let testButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTestData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "UIKit Timer Display Test"
        
        // 配置测试按钮
        testButton.setTitle("Test Timer Update", for: .normal)
        testButton.addTarget(self, action: #selector(testTimerUpdate), for: .touchUpInside)
        
        // 添加子视图
        view.addSubview(timerDisplayView)
        view.addSubview(testButton)
    }
    
    private func setupConstraints() {
        timerDisplayView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        testButton.snp.makeConstraints { make in
            make.top.equalTo(timerDisplayView.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }
    }
    
    private func setupTestData() {
        // 初始状态：25分钟番茄钟
        timerDisplayView.updateTimer(
            timeRemaining: 25 * 60, // 25分钟
            totalTime: 25 * 60,
            isRunning: false,
            isPaused: false
        )
    }
    
    @objc private func testTimerUpdate() {
        // 模拟运行中的计时器：剩余15分钟
        timerDisplayView.updateTimer(
            timeRemaining: 15 * 60 + 30, // 15:30
            totalTime: 25 * 60,
            isRunning: true,
            isPaused: false
        )
        
        // 2秒后模拟暂停状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.timerDisplayView.updateTimer(
                timeRemaining: 15 * 60 + 28, // 15:28
                totalTime: 25 * 60,
                isRunning: true,
                isPaused: true
            )
        }
    }
}