import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black
        
        if let previewLayer = previewLayer {
            // 确保预览层没有父层
            previewLayer.removeFromSuperlayer()
            
            // 设置预览层属性
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            
            // 添加到视图层
            view.layer.addSublayer(previewLayer)
            
            // 确保连接启用
            previewLayer.connection?.isEnabled = true
            
            print("🎥 CameraPreviewView: Preview layer added to view")
            print("🎥 CameraPreviewView: Connection enabled: \(previewLayer.connection?.isEnabled ?? false)")
            print("🎥 CameraPreviewView: Session running: \(previewLayer.session?.isRunning ?? false)")
        } else {
            print("🎥 CameraPreviewView: No preview layer provided")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let previewLayer = previewLayer else { return }
        
        // 更新frame
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = uiView.bounds
        CATransaction.commit()
        
        // 确保预览层在正确的位置
        if previewLayer.superlayer != uiView.layer {
            previewLayer.removeFromSuperlayer()
            uiView.layer.addSublayer(previewLayer)
            print("🎥 CameraPreviewView: Preview layer re-added to view")
        }
        
        // 确保连接启用
        if let connection = previewLayer.connection, !connection.isEnabled {
            connection.isEnabled = true
            print("🎥 CameraPreviewView: Re-enabled preview layer connection")
        }
    }
}

struct CameraPermissionView: View {
    let onRequestPermission: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("需要摄像头权限")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("HealthyCode需要访问摄像头来检测您的体态，帮助您保持健康的工作姿势。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("授权摄像头访问") {
                onRequestPermission()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct CameraUnavailableView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("摄像头不可用")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("应用将以仅计时器模式运行。您仍然可以使用番茄工作法功能。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    VStack {
        CameraPermissionView {
            print("Request permission tapped")
        }
        
        Divider()
        
        CameraUnavailableView()
    }
}