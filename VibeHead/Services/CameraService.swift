import AVFoundation
import UIKit
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var isSessionRunning = false
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    
    // Delegate for processing video frames
    weak var frameDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    override init() {
        super.init()
        checkCameraPermission()
        setupCaptureSession()
    }
    
    // MARK: - Permission Handling
    
    func checkCameraPermission() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestCameraPermission() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        
        await MainActor.run {
            self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
        
        return status
    }
    
    // MARK: - Session Setup
    
    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            self?.configureCaptureSession()
        }
    }
    
    private func configureCaptureSession() {
        guard authorizationStatus == .authorized else {
            print("Camera permission not granted")
            return
        }
        
        captureSession.beginConfiguration()
        
        // Configure session preset for optimal performance
        if captureSession.canSetSessionPreset(.medium) {
            captureSession.sessionPreset = .medium
        }
        
        // Setup video input (front camera)
        setupVideoInput()
        
        // Setup video output
        setupVideoOutput()
        
        // Setup preview layer
        setupPreviewLayer()
        
        captureSession.commitConfiguration()
    }
    
    private func setupVideoInput() {
        // Remove existing input if any
        if let currentInput = videoDeviceInput {
            captureSession.removeInput(currentInput)
        }
        
        // Get front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                       for: .video, 
                                                       position: .front) else {
            print("Front camera not available")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: frontCamera)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                videoDeviceInput = videoInput
            }
        } catch {
            print("Error creating video input: \(error)")
        }
    }
    
    private func setupVideoOutput() {
        videoDataOutput = AVCaptureVideoDataOutput()
        
        guard let videoOutput = videoDataOutput else { return }
        
        // Configure video output settings
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        // Set frame rate to 15fps for battery optimization
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            
            // Set delegate for frame processing
            let videoQueue = DispatchQueue(label: "camera.video.queue")
            videoOutput.setSampleBufferDelegate(frameDelegate, queue: videoQueue)
        }
    }
    
    private func setupPreviewLayer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            
            self.previewLayer = previewLayer
        }
    }
    
    // MARK: - Session Control
    
    func startSession() {
        guard authorizationStatus == .authorized else {
            print("Cannot start session: camera permission not granted")
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = self.captureSession.isRunning
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    // MARK: - Frame Delegate Management
    
    func setFrameDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate?) {
        frameDelegate = delegate
        
        if let videoOutput = videoDataOutput {
            let videoQueue = DispatchQueue(label: "camera.video.queue")
            videoOutput.setSampleBufferDelegate(delegate, queue: videoQueue)
        }
    }
}

// MARK: - Camera Permission Status Extension

extension AVAuthorizationStatus {
    var isAuthorized: Bool {
        return self == .authorized
    }
    
    var isDenied: Bool {
        return self == .denied || self == .restricted
    }
    
    var localizedDescription: String {
        switch self {
        case .authorized:
            return "已授权"
        case .denied:
            return "已拒绝"
        case .restricted:
            return "受限制"
        case .notDetermined:
            return "未确定"
        @unknown default:
            return "未知状态"
        }
    }
}