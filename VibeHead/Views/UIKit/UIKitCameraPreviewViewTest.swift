//
//  UIKitCameraPreviewViewTest.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import UIKit
import SnapKit

#if DEBUG
/// 测试和预览UIKitCameraPreviewView的便利类
class UIKitCameraPreviewViewTest {
    
    /// 创建测试视图控制器
    /// - Returns: 包含摄像头预览视图的测试视图控制器
    static func createTestViewController() -> UIViewController {
        return TestViewController()
    }
    
    /// 创建不同状态的预览实例
    /// - Parameter state: 要模拟的状态
    /// - Returns: 配置好的预览视图
    static func createPreviewInstance(for state: PreviewState) -> UIKitCameraPreviewView {
        let previewView = UIKitCameraPreviewView()
        
        // 直接使用预览视图，不需要配置服务
        
        // 根据状态配置视图（通过摄像头服务）
        switch state {
        case .notDetermined:
            // 默认状态，不需要额外配置
            break
        case .denied:
            // 模拟权限被拒绝状态 - 通过通知模拟
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: .cameraErrorOccurred,
                    object: HealthyCodeError.cameraPermissionDenied
                )
            }
        case .authorized:
            // 模拟权限已授权状态
            break
        case .error(let error):
            // 模拟错误状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: .cameraErrorOccurred,
                    object: error
                )
            }
        }
        
        return previewView
    }
    
    /// 预览状态枚举
    enum PreviewState {
        case notDetermined
        case denied
        case authorized
        case error(HealthyCodeError)
    }
}

// MARK: - 测试视图控制器

private class TestViewController: UIViewController {
    private var cameraPreviewView: UIKitCameraPreviewView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "摄像头预览测试"
        
        // 创建摄像头预览视图
        cameraPreviewView = UIKitCameraPreviewView()
        
        // 添加到视图控制器
        view.addSubview(cameraPreviewView)
        
        // 设置约束
        cameraPreviewView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(200)
        }
        
        // 直接启动预览，不需要配置服务
        
        // 设置回调
        cameraPreviewView.onPermissionRequested = {
            print("权限请求回调被触发")
        }
        
        cameraPreviewView.onSettingsRequested = {
            print("设置请求回调被触发")
        }
        
        // 添加控制按钮
        let startButton = UIButton(type: .system)
        startButton.setTitle("开始预览", for: .normal)
        startButton.backgroundColor = .primaryBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 8
        startButton.addTarget(self, action: #selector(startPreviewAction), for: .touchUpInside)
        
        let stopButton = UIButton(type: .system)
        stopButton.setTitle("停止预览", for: .normal)
        stopButton.backgroundColor = .alertRed
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 8
        stopButton.addTarget(self, action: #selector(stopPreviewAction), for: .touchUpInside)
        
        let buttonStackView = UIStackView(arrangedSubviews: [startButton, stopButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        
        view.addSubview(buttonStackView)
        
        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(cameraPreviewView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }
    
    @objc private func startPreviewAction() {
        cameraPreviewView.startPreview()
    }
    
    @objc private func stopPreviewAction() {
        cameraPreviewView.stopPreview()
    }
}

#endif