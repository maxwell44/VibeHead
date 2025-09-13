import Foundation
import Vision
import AVFoundation
import Combine

class PostureDetectionService: NSObject, PostureDetectionServiceProtocol, @unchecked Sendable {
    @Published var currentPosture: PostureType = .excellent
    @Published var isDetecting = false
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var badPostureDuration: TimeInterval = 0
    @Published var lastFaceObservation: VNFaceObservation?
    
    var previewLayer: AVCaptureVideoPreviewLayer? {
        // TODO: Will be implemented when camera integration is moved to WorkSessionViewController
        return nil
    }
    
    // TODO: CameraService removed - camera functionality will be integrated directly in WorkSessionViewController
    // private let cameraService = CameraService()
    private let feedbackService = FeedbackService()
    private var postureWarningService: PostureWarningService?
    private var performanceMonitor: PerformanceMonitorService?
    private var cancellables = Set<AnyCancellable>()
    
    // Performance optimization
    private var lastProcessingTime: CFTimeInterval = 0
    private var processingInterval: TimeInterval = 1.0 / 15.0 // Default 15fps
    private var frameSkipCounter = 0
    
    // Vision Framework components
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    private let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    private let sequenceHandler = VNSequenceRequestHandler()
    
    // Posture tracking
    private var postureHistory: [PostureRecord] = []
    private var currentPostureStartTime: Date?
    private var badPostureStartTime: Date?
    private let postureChangeThreshold: TimeInterval = 1.0 // 1 second minimum before posture change
    
    // Publishers
    private let postureChangeSubject = PassthroughSubject<PostureType, Never>()
    var postureChangePublisher: AnyPublisher<PostureType, Never> {
        postureChangeSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        
        // 立即设置基本配置
        setupVisionRequests()
        
        // 延迟初始化重型操作到后台队列
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupCameraService()
            
            DispatchQueue.main.async {
                self?.observeCameraPermission()
                self?.setupWarningService()
                self?.setupPerformanceMonitoring()
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupVisionRequests() {
        // Configure face detection request
        faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
        
        // Configure face landmarks request for more detailed analysis
        faceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
    }
    
    // TODO: Camera service setup removed - will be handled by WorkSessionViewController
    private func setupCameraService() {
        // Camera service functionality will be integrated directly in WorkSessionViewController
        // This method is kept for future reference but functionality is disabled
        
        // Set initial camera permission status
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    private func observeCameraPermission() {
        $cameraPermissionStatus
            .sink { [weak self] status in
                if status == .authorized {
                    self?.setupDetection()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupWarningService() {
        let settings = AppSettings.default
        postureWarningService = PostureWarningService(settings: settings)
        
        // Set up warning callback
        postureWarningService?.setWarningCallback { [weak self] posture in
            self?.handlePostureWarning(posture)
        }
    }
    
    private func setupPerformanceMonitoring() {
        performanceMonitor = PerformanceMonitorService()
        
        // Monitor performance changes
        performanceMonitor?.$recommendedFrameRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frameRate in
                self?.updateProcessingInterval(frameRate)
            }
            .store(in: &cancellables)
        
        // Listen for cleanup notifications
        NotificationCenter.default.publisher(for: .performanceCleanupRequired)
            .sink { [weak self] _ in
                self?.performMemoryCleanup()
            }
            .store(in: &cancellables)
    }
    
    private func updateProcessingInterval(_ frameRate: Double) {
        processingInterval = 1.0 / frameRate
        print("Posture detection processing interval updated to: \(processingInterval)s")
    }
    
    private func performMemoryCleanup() {
        // Clear posture history if memory is low
        if postureHistory.count > 100 {
            // Keep only recent 50 records
            postureHistory = Array(postureHistory.suffix(50))
        }
        
        // Clear cached face observations
        lastFaceObservation = nil
        
        print("Posture detection service memory cleanup performed")
    }
    
    private func handlePostureWarning(_ posture: PostureType) {
        let settings = AppSettings.default
        feedbackService.playPostureWarning(
            enableAudio: settings.enableAudioAlerts,
            enableHaptic: settings.enableHapticFeedback
        )
        
        print("体态警告: \(posture.rawValue) 持续时间过长")
    }
    
    private func setupDetection() {
        // Additional setup when camera permission is granted
        print("Camera permission granted, detection ready")
        
        // TODO: Camera preview startup will be handled by WorkSessionViewController
        // Camera service functionality has been moved to WorkSessionViewController
    }
    
    // MARK: - Public Interface
    
    func startDetection() {
        do {
            try validateDetectionRequirements()
            
            isDetecting = true
            currentPostureStartTime = Date()
            
            print("🔍 体态检测已启动")
        } catch {
            handleDetectionError(error)
        }
    }
    
    private func validateDetectionRequirements() throws {
        // 更新摄像头权限状态
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        guard cameraPermissionStatus == .authorized else {
            throw HealthyCodeError.cameraPermissionDenied
        }
        
        guard isPostureDetectionSupported() else {
            throw HealthyCodeError.visionFrameworkError(
                NSError(domain: "VisionFramework", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "设备不支持体态检测功能"
                ])
            )
        }
    }
    
    private func handleDetectionError(_ error: Error) {
        let healthyCodeError: HealthyCodeError
        
        if let hcError = error as? HealthyCodeError {
            healthyCodeError = hcError
        } else {
            healthyCodeError = .visionFrameworkError(error)
        }
        
        DispatchQueue.main.async { [weak self] in
            print("Detection error: \(healthyCodeError.localizedDescription)")
            
            // Graceful degradation - continue with timer-only mode
            self?.handleGracefulDegradation(healthyCodeError)
            
            // Notify UI about the error
            NotificationCenter.default.post(
                name: .postureDetectionErrorOccurred,
                object: healthyCodeError
            )
        }
    }
    
    private func handleGracefulDegradation(_ error: HealthyCodeError) {
        switch error {
        case .cameraPermissionDenied:
            // Continue with timer-only mode
            print("Continuing in timer-only mode due to camera permission denial")
            
        case .cameraNotAvailable:
            // Retry after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.retryDetection()
            }
            
        case .visionFrameworkError:
            // Reduce processing complexity
            processingInterval = min(processingInterval * 2.0, 2.0)
            print("Reduced processing complexity due to Vision Framework error")
            
        default:
            break
        }
    }
    
    private func retryDetection() {
        guard !isDetecting else { return }
        
        print("Retrying posture detection...")
        startDetection()
    }
    
    func stopDetection() {
        isDetecting = false
        postureWarningService?.stopMonitoring()
        
        // Record final posture if any
        recordCurrentPosture()
        
        print("🔍 体态检测已停止")
    }
    
    func requestCameraPermission() async -> Bool {
        // TODO: Camera permission will be handled by WorkSessionViewController
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        
        await MainActor.run {
            self.cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Handle permission result
            if !granted {
                self.handleDetectionError(HealthyCodeError.cameraPermissionDenied)
            }
        }
        
        return granted
    }
    
    // MARK: - Vision Processing
    
    func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard isDetecting else { return }
        
        // Apply performance-based frame throttling
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessingTime >= processingInterval else {
            frameSkipCounter += 1
            return
        }
        
        lastProcessingTime = currentTime
        
        // Check if we should reduce processing based on performance
        if let settings = performanceMonitor?.optimizeForCurrentConditions(),
           !settings.enableAdvancedFeatures {
            // Skip every other frame for better performance
            frameSkipCounter += 1
            if frameSkipCounter % 2 != 0 {
                return
            }
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Create Vision request - use fewer requests if performance is constrained
        let requests: [VNRequest]
        if let settings = performanceMonitor?.optimizeForCurrentConditions(),
           settings.enableAdvancedFeatures {
            requests = [faceDetectionRequest, faceLandmarksRequest]
        } else {
            // Use only basic face detection for better performance
            requests = [faceDetectionRequest]
        }
        
        // Process the frame
        do {
            try sequenceHandler.perform(requests, on: pixelBuffer)
            
            // Handle face detection results
            let faceResults = faceDetectionRequest.results as? [VNFaceObservation] ?? []
            let landmarkResults = (requests.count > 1) ? (faceLandmarksRequest.results as? [VNFaceObservation] ?? []) : []
            
            // Use the most detailed results available
            if !landmarkResults.isEmpty {
                print("🔍 Using landmarks results: \(landmarkResults.count) faces")
                handleFaceLandmarksResults(landmarkResults)
            } else if !faceResults.isEmpty {
                print("🔍 Using face detection results: \(faceResults.count) faces")
                handleFaceDetectionResults(faceResults)
            } else {
                // No face detected in any request
                print("🔍 No face detected in any request, setting .notPresent")
                DispatchQueue.main.async { [weak self] in
                    self?.updatePosture(.notPresent)
                }
            }
            
        } catch {
            print("Vision processing error: \(error)")
            // Handle Vision Framework errors gracefully
            handleVisionError(error)
        }
    }
    
    private func handleVisionError(_ error: Error) {
        let visionError = HealthyCodeError.visionFrameworkError(error)
        
        // Log the error but continue operation
        print("Vision Framework error: \(visionError.localizedDescription)")
        
        // Reduce processing frequency temporarily
        processingInterval = min(processingInterval * 1.5, 1.0) // Max 1 second interval
        
        // Notify about the error but don't stop detection
        DispatchQueue.main.async { [weak self] in
            print("Vision processing temporarily reduced due to error")
            
            // Post notification for UI to show warning
            NotificationCenter.default.post(
                name: .visionProcessingErrorOccurred,
                object: visionError
            )
            
            // Try to recover after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.attemptVisionRecovery()
            }
        }
    }
    
    private func attemptVisionRecovery() {
        // Reset processing interval to normal
        if let frameRate = performanceMonitor?.recommendedFrameRate {
            processingInterval = 1.0 / frameRate
        } else {
            processingInterval = 1.0 / 15.0 // Default
        }
        
        print("Attempting Vision Framework recovery")
    }
    
    private func handleFaceDetectionResults(_ faces: [VNFaceObservation]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // At this point we know faces is not empty (checked in caller)
            if let primaryFace = faces.first {
                self.lastFaceObservation = primaryFace
                self.analyzeFaceObservation(primaryFace)
            }
        }
    }
    
    private func handleFaceLandmarksResults(_ faces: [VNFaceObservation]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // At this point we know faces is not empty (checked in caller)
            if let primaryFace = faces.first {
                self.lastFaceObservation = primaryFace
                self.analyzeDetailedFacePosture(primaryFace)
            }
        }
    }
    
    private func analyzeFaceObservation(_ face: VNFaceObservation) {
        // Use detailed posture analysis with face angles
        let newPosture = classifyDetailedPosture(face)
        updatePosture(newPosture)
    }
    
    private func analyzeDetailedFacePosture(_ face: VNFaceObservation) {
        // Enhanced analysis using landmarks and angles
        let newPosture = classifyDetailedPosture(face)
        updatePosture(newPosture)
    }
    
    private func classifyDetailedPosture(_ face: VNFaceObservation) -> PostureType {
        // Priority 1: Check distance (too close)
        if isTooClose(face) {
            return .tooClose
        }
        
        // Priority 2: Check head angles using face observation data
        if isLookingDown(face) {
            return .lookingDown
        }
        
        if isHeadTilted(face) {
            return .tilted
        }
        
        return .excellent
    }
    
    // MARK: - Posture Classification Methods
    
    private func isTooClose(_ face: VNFaceObservation) -> Bool {
        let boundingBox = face.boundingBox
        
        // Face takes up more than 60% of frame height indicates too close
        return boundingBox.height > 0.6
    }
    
    private func isLookingDown(_ face: VNFaceObservation) -> Bool {
        // Use pitch angle if available
        if let pitch = face.pitch {
            // Pitch < -0.3 radians (~-17 degrees) indicates looking down
            return pitch.doubleValue < -0.3
        }
        
        // Fallback: use face position in frame
        let boundingBox = face.boundingBox
        let centerY = boundingBox.midY
        
        // Face in lower part of frame suggests looking down
        return centerY < 0.35
    }
    
    private func isHeadTilted(_ face: VNFaceObservation) -> Bool {
        // Use roll angle if available
        if let roll = face.roll {
            // Roll > 0.25 radians (~14 degrees) indicates head tilt
            return abs(roll.doubleValue) > 0.25
        }
        
        // Fallback: analyze face landmarks for tilt
        return analyzeFaceTiltFromLandmarks(face)
    }
    
    private func analyzeFaceTiltFromLandmarks(_ face: VNFaceObservation) -> Bool {
        guard let landmarks = face.landmarks else { return false }
        
        // Analyze eye positions to detect tilt
        if let leftEye = landmarks.leftEye,
           let rightEye = landmarks.rightEye {
            
            let leftEyePoints = leftEye.normalizedPoints
            let rightEyePoints = rightEye.normalizedPoints
            
            guard !leftEyePoints.isEmpty && !rightEyePoints.isEmpty else { return false }
            
            // Calculate average eye positions
            let leftEyeCenter = averagePoint(leftEyePoints)
            let rightEyeCenter = averagePoint(rightEyePoints)
            
            // Calculate angle between eyes
            let deltaY = rightEyeCenter.y - leftEyeCenter.y
            let deltaX = rightEyeCenter.x - leftEyeCenter.x
            
            let angle = atan2(deltaY, deltaX)
            
            // Tilt threshold: ~15 degrees
            return abs(angle) > 0.26 // ~15 degrees in radians
        }
        
        return false
    }
    
    private func averagePoint(_ points: [CGPoint]) -> CGPoint {
        let sum = points.reduce(CGPoint.zero) { result, point in
            CGPoint(x: result.x + point.x, y: result.y + point.y)
        }
        
        return CGPoint(x: sum.x / CGFloat(points.count), 
                      y: sum.y / CGFloat(points.count))
    }
    
    // MARK: - Advanced Analysis Methods
    
    private func calculateHeadPose(_ face: VNFaceObservation) -> (pitch: Double, roll: Double, yaw: Double) {
        let pitch = face.pitch?.doubleValue ?? 0.0
        let roll = face.roll?.doubleValue ?? 0.0  
        let yaw = face.yaw?.doubleValue ?? 0.0
        
        return (pitch: pitch, roll: roll, yaw: yaw)
    }
    
    private func isPostureHealthy(pitch: Double, roll: Double, yaw: Double, distance: Double) -> Bool {
        // Define healthy ranges
        let healthyPitchRange = -0.2...0.2  // ~±11 degrees
        let healthyRollRange = -0.2...0.2   // ~±11 degrees  
        let healthyYawRange = -0.3...0.3    // ~±17 degrees
        let healthyDistanceRange = 0.2...0.6 // Face height ratio
        
        return healthyPitchRange.contains(pitch) &&
               healthyRollRange.contains(roll) &&
               healthyYawRange.contains(yaw) &&
               healthyDistanceRange.contains(distance)
    }
    
    private func updatePosture(_ newPosture: PostureType) {
        print("🔍 updatePosture called: \(newPosture.rawValue), current: \(currentPosture.rawValue)")
        
        guard newPosture != currentPosture else { 
            // Update bad posture duration if still in bad posture
            print("🔍 Same posture, updating duration only")
            updateBadPostureDuration()
            return 
        }
        
        // Record the previous posture duration
        recordCurrentPosture()
        
        // Update to new posture
        currentPosture = newPosture
        currentPostureStartTime = Date()
        
        // Track bad posture timing
        if newPosture.isHealthy {
            badPostureStartTime = nil
            badPostureDuration = 0
        } else {
            badPostureStartTime = Date()
        }
        
        // Update warning service
        postureWarningService?.updatePosture(newPosture)
        
        // Notify observers
        postureChangeSubject.send(newPosture)
        
        print("Posture changed to: \(newPosture.rawValue)")
    }
    
    private func updateBadPostureDuration() {
        guard !currentPosture.isHealthy,
              let startTime = badPostureStartTime else { 
            badPostureDuration = 0
            return 
        }
        
        badPostureDuration = Date().timeIntervalSince(startTime)
    }
    
    private func recordCurrentPosture() {
        guard let startTime = currentPostureStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Only record if duration is significant
        if duration >= postureChangeThreshold {
            let record = PostureRecord(
                posture: currentPosture,
                startTime: startTime,
                duration: duration
            )
            
            postureHistory.append(record)
        }
    }
    
    // MARK: - Data Access
    
    func getPostureHistory() -> [PostureRecord] {
        return postureHistory
    }
    
    func clearPostureHistory() {
        postureHistory.removeAll()
        currentPostureStartTime = Date()
    }
    
    func getCurrentSessionDuration() -> TimeInterval {
        guard let startTime = currentPostureStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func isPostureDetectionSupported() -> Bool {
        // Check if device supports Vision Framework and has front camera
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil else {
            return false
        }
        
        // Vision Framework is available on iOS 11+
        if #available(iOS 11.0, *) {
            return true
        }
        
        return false
    }
    
    func updateSettings(_ settings: AppSettings) {
        postureWarningService?.updateSettings(settings)
    }
    
    func getCurrentBadPostureDuration() -> TimeInterval {
        return postureWarningService?.currentBadPostureDuration ?? 0
    }
    
    // MARK: - Debug Methods
    
    func debugCameraStatus() {
        // TODO: Camera debugging will be handled by WorkSessionViewController
        print("Camera service functionality moved to WorkSessionViewController")
    }
    
    func restartCamera() {
        // TODO: Camera restart will be handled by WorkSessionViewController
        print("Camera service functionality moved to WorkSessionViewController")
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension PostureDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, 
                      didOutput sampleBuffer: CMSampleBuffer, 
                      from connection: AVCaptureConnection) {
        processVideoFrame(sampleBuffer)
    }
    
    func captureOutput(_ output: AVCaptureOutput, 
                      didDrop sampleBuffer: CMSampleBuffer, 
                      from connection: AVCaptureConnection) {
        // Handle dropped frames if needed
        print("Frame dropped")
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let postureDetectionErrorOccurred = Notification.Name("postureDetectionErrorOccurred")
    static let visionProcessingErrorOccurred = Notification.Name("visionProcessingErrorOccurred")
}