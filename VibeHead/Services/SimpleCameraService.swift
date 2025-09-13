import AVFoundation
import UIKit
import Combine

class SimpleCameraService: NSObject, ObservableObject {
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isRunning = false
    
    private let session = AVCaptureSession()
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func setupCamera() {
        // 1. 检查权限
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            print("❌ 没有摄像头权限")
            return
        }
        
        // 2. 获取前置摄像头
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("❌ 找不到前置摄像头")
            return
        }
        
        do {
            // 3. 创建输入
            let input = try AVCaptureDeviceInput(device: camera)
            
            // 4. 配置会话
            session.beginConfiguration()
            session.sessionPreset = .medium
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            session.commitConfiguration()
            
            // 5. 创建预览层
            DispatchQueue.main.async {
                let preview = AVCaptureVideoPreviewLayer(session: self.session)
                preview.videoGravity = .resizeAspectFill
                self.previewLayer = preview
                
                // 6. 启动会话
                DispatchQueue.global(qos: .userInitiated).async {
                    self.session.startRunning()
                    DispatchQueue.main.async {
                        self.isRunning = self.session.isRunning
                        print("✅ 摄像头启动: \(self.isRunning)")
                    }
                }
            }
            
        } catch {
            print("❌ 摄像头设置失败: \(error)")
        }
    }
    
    func requestPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        if granted {
            DispatchQueue.main.async {
                self.setupCamera()
            }
        }
        return granted
    }
}