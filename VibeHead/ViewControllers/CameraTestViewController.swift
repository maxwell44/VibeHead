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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "摄像头测试"
        
        // 添加导航栏关闭按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        checkPermissionAndSetup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
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
        
        // 设置视频方向
        if let connection = previewLayer.connection {
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
        
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        // 添加一个拍照按钮演示
        let btn = UIButton(type: .system)
        btn.setTitle("拍照", for: .normal)
        btn.backgroundColor = UIColor(white: 0.1, alpha: 0.6)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 6
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        view.addSubview(btn)
        
        NSLayoutConstraint.activate([
            btn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.widthAnchor.constraint(equalToConstant: 80),
            btn.heightAnchor.constraint(equalToConstant: 44)
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