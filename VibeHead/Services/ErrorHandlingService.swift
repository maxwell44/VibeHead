import Foundation
import Combine
import AVFoundation

class ErrorHandlingService: ObservableObject {
    @Published var currentError: HealthyCodeError?
    @Published var isInGracefulDegradationMode = false
    @Published var errorHistory: [ErrorRecord] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let maxErrorHistory = 50
    
    init() {
        setupErrorMonitoring()
    }
    
    // MARK: - Error Monitoring Setup
    
    private func setupErrorMonitoring() {
        // TODO: Camera error monitoring will be handled by WorkSessionViewController
        // Camera service functionality has been moved to WorkSessionViewController
        // NotificationCenter.default.publisher(for: .cameraErrorOccurred)
        //     .compactMap { $0.object as? HealthyCodeError }
        //     .sink { [weak self] error in
        //         self?.handleError(error, source: .camera)
        //     }
        //     .store(in: &cancellables)
        
        // Monitor posture detection errors
        NotificationCenter.default.publisher(for: .postureDetectionErrorOccurred)
            .compactMap { $0.object as? HealthyCodeError }
            .sink { [weak self] error in
                self?.handleError(error, source: .postureDetection)
            }
            .store(in: &cancellables)
        
        // Monitor vision processing errors
        NotificationCenter.default.publisher(for: .visionProcessingErrorOccurred)
            .compactMap { $0.object as? HealthyCodeError }
            .sink { [weak self] error in
                self?.handleError(error, source: .visionProcessing)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: HealthyCodeError, source: ErrorSource) {
        // Record the error
        let errorRecord = ErrorRecord(
            error: error,
            source: source,
            timestamp: Date(),
            recoveryAttempted: false
        )
        
        errorHistory.append(errorRecord)
        
        // Limit error history size
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst()
        }
        
        // Update current error
        currentError = error
        
        // Determine if graceful degradation is needed
        updateGracefulDegradationMode(for: error, source: source)
        
        // Log the error
        logError(errorRecord)
        
        // Attempt recovery if appropriate
        attemptRecovery(for: error, source: source)
    }
    
    private func updateGracefulDegradationMode(for error: HealthyCodeError, source: ErrorSource) {
        switch error {
        case .cameraPermissionDenied:
            isInGracefulDegradationMode = true
            
        case .cameraNotAvailable:
            isInGracefulDegradationMode = true
            
        case .visionFrameworkError:
            // Temporary degradation for vision errors
            isInGracefulDegradationMode = true
            
            // Auto-recover after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                self?.attemptRecoveryFromGracefulDegradation()
            }
            
        default:
            break
        }
    }
    
    private func logError(_ errorRecord: ErrorRecord) {
        print("🚨 Error occurred:")
        print("   Source: \(errorRecord.source)")
        print("   Error: \(errorRecord.error.localizedDescription)")
        print("   Time: \(errorRecord.timestamp)")
        
        if let suggestion = errorRecord.error.recoverySuggestion {
            print("   Suggestion: \(suggestion)")
        }
    }
    
    // MARK: - Recovery Mechanisms
    
    private func attemptRecovery(for error: HealthyCodeError, source: ErrorSource) {
        switch error {
        case .cameraNotAvailable:
            // Retry camera initialization after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.retryCameraInitialization()
            }
            
        case .visionFrameworkError:
            // Reduce processing complexity
            NotificationCenter.default.post(name: .reduceProcessingComplexity, object: nil)
            
        case .dataCorruption:
            // Attempt data recovery
            attemptDataRecovery()
            
        default:
            break
        }
    }
    
    private func retryCameraInitialization() {
        print("Attempting camera recovery...")
        NotificationCenter.default.post(name: .retryCameraInitialization, object: nil)
    }
    
    private func attemptDataRecovery() {
        print("Attempting data recovery...")
        NotificationCenter.default.post(name: .attemptDataRecovery, object: nil)
    }
    
    private func attemptRecoveryFromGracefulDegradation() {
        guard isInGracefulDegradationMode else { return }
        
        print("Attempting recovery from graceful degradation mode...")
        
        // Check if conditions have improved
        if canExitGracefulDegradation() {
            isInGracefulDegradationMode = false
            currentError = nil
            
            // Notify services to resume normal operation
            NotificationCenter.default.post(name: .resumeNormalOperation, object: nil)
        }
    }
    
    private func canExitGracefulDegradation() -> Bool {
        // Check if the conditions that caused graceful degradation have been resolved
        guard let currentError = currentError else { return true }
        
        switch currentError {
        case .cameraPermissionDenied:
            // Check if permission has been granted
            return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
            
        case .cameraNotAvailable:
            // Check if camera is now available
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
            
        case .visionFrameworkError:
            // Allow recovery after time has passed
            return true
            
        default:
            return true
        }
    }
    
    // MARK: - Public Interface
    
    func clearCurrentError() {
        currentError = nil
    }
    
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    func getRecentErrors(limit: Int = 10) -> [ErrorRecord] {
        return Array(errorHistory.suffix(limit))
    }
    
    func getErrorSummary() -> ErrorSummary {
        let cameraErrors = errorHistory.filter { $0.source == .camera }.count
        let postureErrors = errorHistory.filter { $0.source == .postureDetection }.count
        let visionErrors = errorHistory.filter { $0.source == .visionProcessing }.count
        
        return ErrorSummary(
            totalErrors: errorHistory.count,
            cameraErrors: cameraErrors,
            postureDetectionErrors: postureErrors,
            visionProcessingErrors: visionErrors,
            isInGracefulDegradation: isInGracefulDegradationMode
        )
    }
    
    func reportError(_ error: HealthyCodeError, source: ErrorSource) {
        handleError(error, source: source)
    }
}

// MARK: - Supporting Types

struct ErrorRecord {
    let error: HealthyCodeError
    let source: ErrorSource
    let timestamp: Date
    var recoveryAttempted: Bool
}

enum ErrorSource: String, CaseIterable {
    case camera = "Camera"
    case postureDetection = "Posture Detection"
    case visionProcessing = "Vision Processing"
    case dataStorage = "Data Storage"
    case settings = "Settings"
}

struct ErrorSummary {
    let totalErrors: Int
    let cameraErrors: Int
    let postureDetectionErrors: Int
    let visionProcessingErrors: Int
    let isInGracefulDegradation: Bool
}

// MARK: - Additional Notification Extensions

extension Notification.Name {
    static let reduceProcessingComplexity = Notification.Name("reduceProcessingComplexity")
    static let retryCameraInitialization = Notification.Name("retryCameraInitialization")
    static let attemptDataRecovery = Notification.Name("attemptDataRecovery")
    static let resumeNormalOperation = Notification.Name("resumeNormalOperation")
}