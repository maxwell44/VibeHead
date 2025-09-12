import Foundation
import Vision
import AVFoundation
import Combine

class PostureDetectionService: NSObject, PostureDetectionServiceProtocol {
    @Published var currentPosture: PostureType = .excellent
    @Published var isDetecting = false
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var badPostureDuration: TimeInterval = 0
    @Published var lastFaceObservation: VNFaceObservation?
    
    var previewLayer: AVCaptureVideoPreviewLayer? {
        return cameraService.previewLayer
    }
    
    private let cameraService = CameraService()
    private let feedbackService = FeedbackService()
    private var postureWarningService: PostureWarningService?
    private var cancellables = Set<AnyCancellable>()
    
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
        setupVisionRequests()
        setupCameraService()
        observeCameraPermission()
        setupWarningService()
    }
    
    // MARK: - Setup
    
    private func setupVisionRequests() {
        // Configure face detection request
        faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
        
        // Configure face landmarks request for more detailed analysis
        faceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
    }
    
    private func setupCameraService() {
        // Set this service as the frame delegate for camera
        cameraService.setFrameDelegate(self)
        
        // Observe camera service state
        cameraService.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.cameraPermissionStatus, on: self)
            .store(in: &cancellables)
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
    }
    
    // MARK: - Public Interface
    
    func startDetection() {
        guard cameraPermissionStatus == .authorized else {
            print("Cannot start detection: camera permission not granted")
            return
        }
        
        isDetecting = true
        currentPostureStartTime = Date()
        cameraService.startSession()
        
        print("Posture detection started")
    }
    
    func stopDetection() {
        isDetecting = false
        cameraService.stopSession()
        postureWarningService?.stopMonitoring()
        
        // Record final posture if any
        recordCurrentPosture()
        
        print("Posture detection stopped")
    }
    
    func requestCameraPermission() async -> Bool {
        let granted = await cameraService.requestCameraPermission()
        
        await MainActor.run {
            self.cameraPermissionStatus = self.cameraService.authorizationStatus
        }
        
        return granted
    }
    
    // MARK: - Vision Processing
    
    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard isDetecting else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Create Vision request
        let requests: [VNRequest] = [faceDetectionRequest, faceLandmarksRequest]
        
        // Process the frame
        do {
            try sequenceHandler.perform(requests, on: pixelBuffer)
            
            // Handle face detection results
            if let faceResults = faceDetectionRequest.results as? [VNFaceObservation] {
                handleFaceDetectionResults(faceResults)
            }
            
            // Handle landmarks results for more detailed analysis
            if let landmarkResults = faceLandmarksRequest.results as? [VNFaceObservation] {
                handleFaceLandmarksResults(landmarkResults)
            }
            
        } catch {
            print("Vision processing error: \(error)")
        }
    }
    
    private func handleFaceDetectionResults(_ faces: [VNFaceObservation]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let primaryFace = faces.first {
                self.lastFaceObservation = primaryFace
                self.analyzeFaceObservation(primaryFace)
            } else {
                // No face detected - could indicate user is away
                self.updatePosture(.excellent) // Default to excellent when no face
            }
        }
    }
    
    private func handleFaceLandmarksResults(_ faces: [VNFaceObservation]) {
        guard let primaryFace = faces.first else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.analyzeDetailedFacePosture(primaryFace)
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
        guard newPosture != currentPosture else { 
            // Update bad posture duration if still in bad posture
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