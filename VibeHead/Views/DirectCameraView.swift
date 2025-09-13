import SwiftUI
import AVFoundation
import UIKit

// MARK: - 相机控制器
class CameraViewController: UIViewController {
    let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermissionAndSetup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
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
            print("❌ 摄像头权限被拒绝")
            break
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .medium
        
        // 前置摄像头
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front
        )
        
        guard let frontDevice = discovery.devices.first else {
            print("❌ 没有找到前置摄像头")
            session.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontDevice)
            if session.canAddInput(input) { 
                session.addInput(input) 
                print("✅ 摄像头输入添加成功")
            }
        } catch {
            print("❌ 相机初始化失败: \(error)")
        }
        
        session.commitConfiguration()
        
        DispatchQueue.main.async {
            self.setupPreview()
            self.session.startRunning()
            print("✅ 摄像头会话启动: \(self.session.isRunning)")
        }
    }
    
    private func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        print("✅ 预览层设置完成")
    }
    
    deinit {
        if session.isRunning { 
            session.stopRunning() 
        }
    }
}

// MARK: - SwiftUI 包装
struct DirectCameraView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    static func dismantleUIViewController(_ uiViewController: CameraViewController, coordinator: ()) {
        if uiViewController.session.isRunning {
            uiViewController.session.stopRunning()
        }
    }
}

// MARK: - 测试视图
struct DirectCameraTestView: View {
    var body: some View {
        VStack {
            Text("直接摄像头测试")
                .font(.title)
                .padding()
            
            DirectCameraView()
                .frame(height: 400)
                .cornerRadius(12)
                .padding()
            
            Text("如果看到画面，说明摄像头工作正常")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DirectCameraTestView()
}