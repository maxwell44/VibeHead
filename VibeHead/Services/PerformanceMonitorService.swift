import Foundation
import UIKit
import Combine
import Darwin

class PerformanceMonitorService: ObservableObject {
    @Published var batteryLevel: Float = 1.0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var memoryUsage: Double = 0.0
    @Published var isLowPowerModeEnabled: Bool = false
    @Published var currentFrameRate: Double = 15.0
    @Published var recommendedFrameRate: Double = 15.0
    
    private var cancellables = Set<AnyCancellable>()
    private let memoryUpdateTimer = Timer.publish(every: 5.0, on: .main, in: .common).autoconnect()
    
    // Performance thresholds
    private let lowBatteryThreshold: Float = 0.2
    private let criticalBatteryThreshold: Float = 0.1
    private let highMemoryThreshold: Double = 80.0 // 80% of available memory
    
    init() {
        setupBatteryMonitoring()
        setupMemoryMonitoring()
        setupLowPowerModeMonitoring()
    }
    
    // MARK: - Battery Monitoring
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Initial battery state
        updateBatteryInfo()
        
        // Monitor battery level changes
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryInfo()
                self?.adjustPerformanceForBattery()
            }
            .store(in: &cancellables)
        
        // Monitor battery state changes
        NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryInfo()
                self?.adjustPerformanceForBattery()
            }
            .store(in: &cancellables)
    }
    
    private func updateBatteryInfo() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
        
        print("Battery level: \(Int(batteryLevel * 100))%, State: \(batteryState)")
    }
    
    private func adjustPerformanceForBattery() {
        let newFrameRate: Double
        
        switch batteryLevel {
        case 0.0..<criticalBatteryThreshold:
            // Critical battery: 5fps
            newFrameRate = 5.0
        case criticalBatteryThreshold..<lowBatteryThreshold:
            // Low battery: 10fps
            newFrameRate = 10.0
        case lowBatteryThreshold..<0.5:
            // Medium battery: 12fps
            newFrameRate = 12.0
        default:
            // Good battery: 15fps
            newFrameRate = 15.0
        }
        
        // Additional adjustment for low power mode
        if isLowPowerModeEnabled {
            recommendedFrameRate = min(newFrameRate, 8.0)
        } else {
            recommendedFrameRate = newFrameRate
        }
        
        print("Recommended frame rate adjusted to: \(recommendedFrameRate)fps")
    }
    
    // MARK: - Memory Monitoring
    
    private func setupMemoryMonitoring() {
        memoryUpdateTimer
            .sink { [weak self] _ in
                self?.updateMemoryUsage()
            }
            .store(in: &cancellables)
        
        // Monitor memory warnings
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    private func updateMemoryUsage() {
        let usage = getMemoryUsage()
        
        DispatchQueue.main.async { [weak self] in
            self?.memoryUsage = usage
        }
        
        if usage > highMemoryThreshold {
            handleHighMemoryUsage()
        }
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemoryMB = Double(info.resident_size) / 1024.0 / 1024.0
            let totalMemoryMB = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0
            return (usedMemoryMB / totalMemoryMB) * 100.0
        }
        
        return 0.0
    }
    
    private func handleMemoryWarning() {
        print("Memory warning received - reducing performance")
        
        // Reduce frame rate temporarily
        recommendedFrameRate = min(recommendedFrameRate, 8.0)
        
        // Trigger cleanup
        triggerMemoryCleanup()
    }
    
    private func handleHighMemoryUsage() {
        print("High memory usage detected: \(memoryUsage)%")
        
        // Reduce frame rate
        recommendedFrameRate = min(recommendedFrameRate, 10.0)
        
        // Trigger cleanup
        triggerMemoryCleanup()
    }
    
    private func triggerMemoryCleanup() {
        // Post notification for services to clean up
        NotificationCenter.default.post(name: .performanceCleanupRequired, object: nil)
    }
    
    // MARK: - Low Power Mode Monitoring
    
    private func setupLowPowerModeMonitoring() {
        // Initial state
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        // Monitor low power mode changes
        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .sink { [weak self] _ in
                self?.updateLowPowerModeState()
            }
            .store(in: &cancellables)
    }
    
    private func updateLowPowerModeState() {
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        print("Low power mode: \(isLowPowerModeEnabled ? "Enabled" : "Disabled")")
        
        adjustPerformanceForBattery()
    }
    
    // MARK: - Frame Rate Control
    
    func updateCurrentFrameRate(_ frameRate: Double) {
        currentFrameRate = frameRate
    }
    
    func shouldReduceProcessing() -> Bool {
        return batteryLevel < lowBatteryThreshold || 
               isLowPowerModeEnabled || 
               memoryUsage > highMemoryThreshold
    }
    
    func getProcessingInterval() -> TimeInterval {
        // Return interval between processing cycles based on performance state
        let baseInterval = 1.0 / recommendedFrameRate
        
        if shouldReduceProcessing() {
            return baseInterval * 2.0 // Double the interval (half the frequency)
        }
        
        return baseInterval
    }
    
    // MARK: - Performance Recommendations
    
    func getPerformanceRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if batteryLevel < criticalBatteryThreshold {
            recommendations.append("电池电量极低，建议连接充电器")
        } else if batteryLevel < lowBatteryThreshold {
            recommendations.append("电池电量较低，已降低检测频率以节省电量")
        }
        
        if isLowPowerModeEnabled {
            recommendations.append("低电量模式已启用，性能已优化")
        }
        
        if memoryUsage > highMemoryThreshold {
            recommendations.append("内存使用率较高，建议关闭其他应用")
        }
        
        return recommendations
    }
    
    // MARK: - Resource Management
    
    func optimizeForCurrentConditions() -> PerformanceSettings {
        return PerformanceSettings(
            frameRate: recommendedFrameRate,
            processingInterval: getProcessingInterval(),
            enableAdvancedFeatures: !shouldReduceProcessing(),
            memoryOptimizationEnabled: memoryUsage > highMemoryThreshold
        )
    }
    
    deinit {
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
}

// MARK: - Performance Settings

struct PerformanceSettings {
    let frameRate: Double
    let processingInterval: TimeInterval
    let enableAdvancedFeatures: Bool
    let memoryOptimizationEnabled: Bool
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let performanceCleanupRequired = Notification.Name("performanceCleanupRequired")
    static let frameRateChanged = Notification.Name("frameRateChanged")
}