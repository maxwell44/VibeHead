import AVFoundation
import UIKit
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var isSessionRunning = false
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var currentFrameRate: Double = 15.0
    
    private let captureSession = AVCaptureSession()
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
            
            self.captureSession.beginConfiguration()
            
            do {
                // Setup video input (front camera)
                try self.setupVideoInput()
                
                // Setup video output
                try self.setupVideoOutput()
                
                self.captureSession.commitConfiguration()
                
                print("Camera session configured successfully after permission granted")
                
                // Start preview immediately after configuration
                DispatchQueue.main.async {
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
        
        // Always setup preview layer
        setupPreviewLayer()
        
        // Only setup input/output if we have permission
        if authorizationStatus == .authorized {
            do {
                // Setup video input (front camera)
                try setupVideoInput()
                
                // Setup video output
                try setupVideoOutput()
                
                captureSession.commitConfiguration()
            } catch {
                captureSession.commitConfiguration()
                handleCameraError(error)
            }
        } else {
            captureSession.commitConfiguration()
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
        
        // Get front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                       for: .video, 
                                                       position: .front) else {
            throw HealthyCodeError.cameraNotAvailable
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: frontCamera)
            
            guard captureSession.canAddInput(videoInput) else {
                throw HealthyCodeError.cameraNotAvailable
            }
            
            captureSession.addInput(videoInput)
            videoDeviceInput = videoInput
        } catch {
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
            
            self.previewLayer = previewLayer
        }
    }
    
    // MARK: - Session Control
    
    func startPreviewOnly() {
        // Start session for preview only, without validation
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = self.captureSession.isRunning
                    print("Camera preview session started: \(self.isSessionRunning)")
                }
            }
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