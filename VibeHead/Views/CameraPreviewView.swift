import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black
        
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = previewLayer {
            previewLayer.frame = uiView.bounds
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