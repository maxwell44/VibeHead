//
//  CameraTestViewController.swift
//  VibeHead
//
//  Created by Kiro on 2025/9/13.
//

import UIKit
import AVFoundation

class CameraTestViewController: UIViewController {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // 圆形摄像头预览容器
    private let cameraContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 140 // 280/2 = 140
        view.clipsToBounds = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "摄像头测试"
        
        // 添加导航栏关闭按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        setupUI()
        checkPermissionAndSetup()
    }
    
    private func setupUI() {
        // 添加标题标签
        let titleLabel = UILabel()
        titleLabel.text = "圆形摄像头预览测试"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // 添加说明标签
        let descriptionLabel = UILabel()
        descriptionLabel.text = "280x280 圆形前置摄像头预览"
        descriptionLabel.font = .systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        view.addSubview(cameraContainerView)
        
        // 设置约束
        cameraContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // 标题标签约束
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 说明标签约束
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 圆形容器约束
            cameraContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraContainerView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            cameraContainerView.widthAnchor.constraint(equalToConstant: 280),
            cameraContainerView.heightAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraContainerView.bounds
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { 
                    DispatchQueue.main.async {
                        self.setupSession()
                    }
                }
            }
        default:
            // 提示用户去设置开启相机权限
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "需要相机权限", message: "请在设置中允许相机访问", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                })
                self.present(alert, animated: true)
            }
        }
    }
    
    private func setupSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            // 找到前置摄像头
            let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInTrueDepthCamera]
            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: .front
            )
            
            guard let frontDevice = discovery.devices.first else {
                print("找不到前置摄像头")
                self.session.commitConfiguration()
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: frontDevice)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
                
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                }
            } catch {
                print("创建 input 失败：", error)
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.setupPreview()
            }
            
            self.session.startRunning()
        }
    }
    
    private func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        // 设置视频方向 - 向左旋转90度
        if let connection = previewLayer.connection {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(270) {
                    connection.videoRotationAngle = 90 // 向左旋转90度
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .landscapeRight // 向左旋转90度
                }
            }
        }
        
        // 将预览层添加到圆形容器中
        previewLayer.frame = cameraContainerView.bounds
        cameraContainerView.layer.addSublayer(previewLayer)
        
        // 添加一个拍照按钮演示
        let btn = UIButton(type: .system)
        btn.setTitle("拍照测试", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 25
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        view.addSubview(btn)
        
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: cameraContainerView.bottomAnchor, constant: 40),
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.widthAnchor.constraint(equalToConstant: 120),
            btn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func takePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        // 若前置摄像头需要镜像效果，后处理时镜像图片即可
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    deinit {
        sessionQueue.async {
            if self.session.isRunning { 
                self.session.stopRunning() 
            }
        }
    }
}

extension CameraTestViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        if let error = error {
            print("拍照失败：", error)
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              var image = UIImage(data: data) else {
            print("无法获取图片数据")
            return
        }
        
        // 注意：前置摄像头通常会返回镜像的图像，按需镜像修正
        image = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
        
        DispatchQueue.main.async {
            // 展示或处理 image
            let iv = UIImageView(image: image)
            iv.contentMode = .scaleAspectFit
            iv.frame = self.view.bounds
            iv.backgroundColor = .black
            iv.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissPreview(_:)))
            iv.addGestureRecognizer(tap)
            self.view.addSubview(iv)
        }
    }
    
    @objc private func dismissPreview(_ tap: UITapGestureRecognizer) {
        tap.view?.removeFromSuperview()
    }
}
