import SwiftUI
import AVFoundation

struct SimpleCameraView: View {
    @StateObject private var camera = SimpleCameraService()
    
    var body: some View {
        VStack {
            // 摄像头预览
            if let previewLayer = camera.previewLayer {
                CameraPreview(previewLayer: previewLayer)
                    .frame(height: 300)
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        Text("摄像头未启动")
                            .foregroundColor(.white)
                    )
            }
            
            Text("状态: \(camera.isRunning ? "运行中" : "已停止")")
                .padding()
            
            Button("请求权限并启动") {
                Task {
                    await camera.requestPermission()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}