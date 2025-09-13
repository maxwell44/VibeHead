import AVFoundation
import UIKit
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var isSessionRunning = false
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var currentFrameRate: Double = 15.0
    
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var performanceMonitor: PerformanceMonitorService?
    private var cancellables = Set<AnyCancellable>()
    
    // Frame rate control
    private var targetFrameRate: Double = 15.0
    private var lastFrameTime: CFTimeInterval = 0
    private let frameRateQueue = DispatchQueue(label: "camera.framerate.queue")
    
    // Delegate for processing video frames
    weak var frameDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    override init() {
        super.init()
        
        // Check if running on simulator
        #if targetEnvironment(simulator)
        print("🎥 ⚠️ Running on iOS Simulator - Camera functionality will be limited")
        #else
        print("🎥 Running on physical device - Camera should work normally")
        #endif
        
        checkCameraPermission()
        setupCaptureSession()
        setupPerformanceMonitoring()
    }
    
    // MARK: - Performance Monitoring Setup
    
    private func setupPerformanceMonitoring() {
        performanceMonitor = PerformanceMonitorService()
        
        // Monitor performance changes
        performanceMonitor?.$recommendedFrameRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newFrameRate in
                self?.updateFrameRate(newFrameRate)
            }
            .store(in: &cancellables)
        
        // Listen for cleanup notifications
        NotificationCenter.default.publisher(for: .performanceCleanupRequired)
            .sink { [weak self] _ in
                self?.performMemoryCleanup()
            }
            .store(in: &cancellables)
    }
    
    private func updateFrameRate(_ newFrameRate: Double) {
        guard newFrameRate != targetFrameRate else { return }
        
        targetFrameRate = newFrameRate
        currentFrameRate = newFrameRate
        
        sessionQueue.async { [weak self] in
            self?.configureFrameRate(newFrameRate)
        }
        
        print("Camera frame rate updated to: \(newFrameRate)fps")
    }
    
    private func configureFrameRate(_ frameRate: Double) {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            // Find the best format for the desired frame rate
            let format = device.activeFormat
            let ranges = format.videoSupportedFrameRateRanges
            
            if let range = ranges.first(where: { $0.maxFrameRate >= frameRate }) {
                let clampedFrameRate = min(frameRate, range.maxFrameRate)
                device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(clampedFrameRate))
                device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(clampedFrameRate))
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error configuring frame rate: \(error)")
        }
    }
    
    private func performMemoryCleanup() {
        sessionQueue.async { [weak self] in
            // Clear any cached frames or buffers
            self?.videoDataOutput?.alwaysDiscardsLateVideoFrames = true
            
            // Force garbage collection
            DispatchQueue.main.async {
                // Trigger memory cleanup
                print("Performing camera service memory cleanup")
            }
        }
    }
    
    // MARK: - Permission Handling
    
    func checkCameraPermission() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestCameraPermission() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        
        await MainActor.run {
            self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            
            // If permission was granted, setup the camera session
            if self.authorizationStatus == .authorized {
                self.setupCameraSessionAfterPermission()
            }
        }
        
        return status
    }
    
    private func setupCameraSessionAfterPermission() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            print("🎥 Setting up camera session after permission granted...")
            
            self.captureSession.beginConfiguration()
            
            do {
                // Setup video input (front camera)
                try self.setupVideoInput()
                
                // Setup video output
                try self.setupVideoOutput()
                
                self.captureSession.commitConfiguration()
                
                print("🎥 Camera session configured successfully after permission granted")
                
                // 确保预览层连接到正确的会话
                DispatchQueue.main.async {
                    if let previewLayer = self.previewLayer {
                        previewLayer.session = self.captureSession
                        previewLayer.connection?.isEnabled = true
                        print("🎥 Preview layer reconnected to session")
                    }
                    
                    // Start preview immediately after configuration
                    self.startPreviewOnly()
                }
            } catch {
                self.captureSession.commitConfiguration()
                self.handleCameraError(error)
            }
        }
    }
    
    func handleCameraPermissionDenied() -> HealthyCodeError {
        return .cameraPermissionDenied
    }
    
    func validateCameraAvailability() throws {
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil else {
            throw HealthyCodeError.cameraNotAvailable
        }
        
        guard authorizationStatus == .authorized else {
            throw HealthyCodeError.cameraPermissionDenied
        }
    }
    
    // MARK: - Session Setup
    
    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            self?.configureCaptureSession()
        }
    }
    
    private func configureCaptureSession() {
        // Don't validate camera availability during initial setup
        // This will be checked when starting the session
        
        captureSession.beginConfiguration()
        
        // Configure session preset for optimal performance
        if captureSession.canSetSessionPreset(.medium) {
            captureSession.sessionPreset = .medium
        }
        
        // Always setup preview layer first
        setupPreviewLayer()
        
        // Only setup input/output if we have permission
        if authorizationStatus == .authorized {
            do {
                // Setup video input (front camera)
                try setupVideoInput()
                
                // Setup video output
                try setupVideoOutput()
                
                captureSession.commitConfiguration()
                
                print("🎥 Session configured successfully with permission")
                
            } catch {
                captureSession.commitConfiguration()
                handleCameraError(error)
            }
        } else {
            captureSession.commitConfiguration()
            print("🎥 Session configured without camera input (no permission yet)")
        }
    }
    
    private func handleCameraError(_ error: Error) {
        let healthyCodeError: HealthyCodeError
        
        if let hcError = error as? HealthyCodeError {
            healthyCodeError = hcError
        } else {
            healthyCodeError = .cameraNotAvailable
        }
        
        DispatchQueue.main.async {
            print("Camera error: \(healthyCodeError.localizedDescription)")
            // Post notification for UI to handle graceful degradation
            NotificationCenter.default.post(
                name: .cameraErrorOccurred,
                object: healthyCodeError
            )
        }
    }
    
    private func setupVideoInput() throws {
        // Remove existing input if any
        if let currentInput = videoDeviceInput {
            captureSession.removeInput(currentInput)
        }
        
        // List all available cameras for debugging
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        print("🎥 Available camera devices:")
        for device in discoverySession.devices {
            print("🎥   - \(device.localizedName) (position: \(device.position.rawValue))")
        }
        
        // Get front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                       for: .video, 
                                                       position: .front) else {
            print("🎥 ❌ No front camera found!")
            
            // Try any available camera as fallback
            if let anyCamera = discoverySession.devices.first {
                print("🎥 Using fallback camera: \(anyCamera.localizedName)")
                try setupVideoInputWithDevice(anyCamera)
                return
            }
            
            throw HealthyCodeError.cameraNotAvailable
        }
        
        print("🎥 ✅ Using front camera: \(frontCamera.localizedName)")
        try setupVideoInputWithDevice(frontCamera)
    }
    
    private func setupVideoInputWithDevice(_ device: AVCaptureDevice) throws {
        do {
            let videoInput = try AVCaptureDeviceInput(device: device)
            
            guard captureSession.canAddInput(videoInput) else {
                print("🎥 ❌ Cannot add video input to session")
                throw HealthyCodeError.cameraNotAvailable
            }
            
            captureSession.addInput(videoInput)
            videoDeviceInput = videoInput
            print("🎥 ✅ Video input added successfully")
        } catch {
            print("🎥 ❌ Error creating video input: \(error)")
            if error is HealthyCodeError {
                throw error
            } else {
                throw HealthyCodeError.cameraNotAvailable
            }
        }
    }
    
    private func setupVideoOutput() throws {
        videoDataOutput = AVCaptureVideoDataOutput()
        
        guard let videoOutput = videoDataOutput else {
            throw HealthyCodeError.cameraNotAvailable
        }
        
        // Configure video output settings for optimal performance
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        // Optimize for performance and battery life
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        // Set sample buffer delegate with frame rate control
        guard captureSession.canAddOutput(videoOutput) else {
            throw HealthyCodeError.cameraNotAvailable
        }
        
        captureSession.addOutput(videoOutput)
        
        // Set delegate for frame processing with throttling
        let videoQueue = DispatchQueue(label: "camera.video.queue", qos: .userInitiated)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
    }
    
    private func setupPreviewLayer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            
            // 确保预览层连接正确
            if let connection = previewLayer.connection {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                print("🎥 Preview layer connection configured: \(connection.isEnabled)")
            }
            
            self.previewLayer = previewLayer
            
            print("🎥 Preview layer created successfully")
            print("🎥 Session has inputs: \(self.captureSession.inputs.count)")
            print("🎥 Session has outputs: \(self.captureSession.outputs.count)")
            print("🎥 Session is running: \(self.captureSession.isRunning)")
            print("🎥 Preview layer connection: \(previewLayer.connection?.isEnabled ?? false)")
        }
    }
    
    // MARK: - Session Control
    
    func startPreviewOnly() {
        print("🎥 Starting preview only...")
        
        // Start session for preview only, without validation
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            print("🎥 Session queue: checking if session is running: \(self.captureSession.isRunning)")
            print("🎥 Session inputs: \(self.captureSession.inputs.count)")
            print("🎥 Session outputs: \(self.captureSession.outputs.count)")
            
            // 确保会话配置正确
            if self.captureSession.inputs.isEmpty && self.authorizationStatus == .authorized {
                print("🎥 No inputs found, reconfiguring session...")
                self.configureCaptureSession()
            }
            
            if !self.captureSession.isRunning {
                print("🎥 Starting capture session...")
                self.captureSession.startRunning()
                
                // 等待一小段时间确保会话完全启动
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isSessionRunning = self.captureSession.isRunning
                    print("🎥 Camera preview session started: \(self.isSessionRunning)")
                    
                    if self.isSessionRunning {
                        print("🎥 ✅ Session is now running successfully!")
                        
                        // 强制更新预览层
                        if let previewLayer = self.previewLayer {
                            print("🎥 Refreshing preview layer connection...")
                            previewLayer.connection?.isEnabled = true
                        }
                    } else {
                        print("🎥 ❌ Session failed to start!")
                        // 尝试重新配置
                        self.sessionQueue.async {
                            self.reconfigureSession()
                        }
                    }
                }
            } else {
                print("🎥 Session was already running")
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        }
    }
    
    private func reconfigureSession() {
        print("🎥 Attempting to reconfigure session...")
        
        captureSession.beginConfiguration()
        
        // 移除所有现有的输入和输出
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        
        do {
            // 重新设置输入和输出
            try setupVideoInput()
            try setupVideoOutput()
            
            captureSession.commitConfiguration()
            
            print("🎥 Session reconfigured successfully")
            
            // 重新启动会话
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
            
        } catch {
            captureSession.commitConfiguration()
            print("🎥 Failed to reconfigure session: \(error)")
        }
    }
    
    func startSession() {
        do {
            try validateCameraAvailability()
        } catch {
            handleCameraError(error)
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = self.captureSession.isRunning
                    
                    // Verify session actually started
                    if !self.isSessionRunning {
                        self.handleCameraError(HealthyCodeError.cameraNotAvailable)
                    }
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
    }
    
    // MARK: - Frame Rate Control
    
    private func shouldProcessFrame() -> Bool {
        let currentTime = CACurrentMediaTime()
        let targetInterval = 1.0 / targetFrameRate
        
        if currentTime - lastFrameTime >= targetInterval {
            lastFrameTime = currentTime
            return true
        }
        
        return false
    }
    
    func getCurrentPerformanceSettings() -> PerformanceSettings? {
        return performanceMonitor?.optimizeForCurrentConditions()
    }
    
    // MARK: - Debug Methods
    
    func debugCameraStatus() {
        print("🎥 === Camera Debug Status ===")
        print("🎥 Authorization Status: \(authorizationStatus.localizedDescription)")
        print("🎥 Session Running: \(captureSession.isRunning)")
        print("🎥 Session Inputs: \(captureSession.inputs.count)")
        print("🎥 Session Outputs: \(captureSession.outputs.count)")
        print("🎥 Preview Layer: \(previewLayer != nil ? "✅" : "❌")")
        
        if let previewLayer = previewLayer {
            print("🎥 Preview Layer Session: \(previewLayer.session === captureSession ? "✅" : "❌")")
            print("🎥 Preview Layer Connection: \(previewLayer.connection?.isEnabled ?? false ? "✅" : "❌")")
            print("🎥 Preview Layer Frame: \(previewLayer.frame)")
        }
        
        // 检查输入设备
        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                print("🎥 Input Device: \(deviceInput.device.localizedName)")
                print("🎥 Input Device Position: \(deviceInput.device.position.rawValue)")
            }
        }
        
        print("🎥 === End Debug Status ===")
    }
    
    func restartCameraSession() {
        print("🎥 Manually restarting camera session...")
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            
            // 等待一下再重启
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sessionQueue.async {
                    self.captureSession.startRunning()
                    
                    DispatchQueue.main.async {
                        self.isSessionRunning = self.captureSession.isRunning
                        print("🎥 Manual restart result: \(self.isSessionRunning)")
                        
                        // 强制刷新预览层
                        if let previewLayer = self.previewLayer {
                            previewLayer.connection?.isEnabled = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, 
                      didOutput sampleBuffer: CMSampleBuffer, 
                      from connection: AVCaptureConnection) {
        
        // Apply frame rate throttling
        guard shouldProcessFrame() else { return }
        
        // Update performance monitor
        performanceMonitor?.updateCurrentFrameRate(currentFrameRate)
        
        // Forward to the actual frame delegate
        frameDelegate?.captureOutput?(output, didOutput: sampleBuffer, from: connection)
    }
    
    func captureOutput(_ output: AVCaptureOutput, 
                      didDrop sampleBuffer: CMSampleBuffer, 
                      from connection: AVCaptureConnection) {
        // Handle dropped frames
        if let delegate = frameDelegate {
            delegate.captureOutput?(output, didDrop: sampleBuffer, from: connection)
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

// MARK: - Notification Extensions

extension Notification.Name {
    static let cameraErrorOccurred = Notification.Name("cameraErrorOccurred")
}