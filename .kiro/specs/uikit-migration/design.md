# UIKit迁移设计文档

## 概述

本设计文档详细描述了将HealthyCode应用从SwiftUI架构完全迁移到UIKit架构的技术方案。迁移将保持所有现有功能，同时采用UIKit的视图控制器模式和SnapKit约束系统，以获得更精细的UI控制和更好的性能。

## 架构设计

### 整体架构转换

```
SwiftUI架构                    UIKit架构
├── App.swift                 ├── AppDelegate.swift
├── SceneDelegate.swift       ├── SceneDelegate.swift (重构)
├── Views/                    ├── ViewControllers/
│   ├── WorkSessionView       │   ├── WorkSessionViewController
│   ├── SettingsView          │   ├── SettingsViewController
│   ├── StatisticsView        │   ├── StatisticsViewController
│   └── ...                   │   └── ...
├── ViewModels/               ├── Views/ (自定义UIView)
│   ├── WorkSessionViewModel  │   ├── TimerDisplayView
│   └── SettingsViewModel     │   ├── PostureStatusView
└── Models/                   │   ├── CameraPreviewView
    └── (保持不变)             │   └── ...
                              ├── ViewModels/ (保持，但调整绑定)
                              └── Models/ (保持不变)
```

### 核心组件映射

| SwiftUI组件 | UIKit组件 | 说明 |
|------------|-----------|------|
| `WorkSessionView` | `WorkSessionViewController` | 主工作界面控制器 |
| `SettingsView` | `SettingsViewController` | 设置界面控制器 |
| `StatisticsView` | `StatisticsViewController` | 统计界面控制器 |
| `TimerDisplayView` | `TimerDisplayView: UIView` | 自定义计时器显示视图 |
| `PostureStatusView` | `PostureStatusView: UIView` | 自定义体态状态视图 |
| `CameraPreviewView` | `CameraPreviewView: UIView` | 摄像头预览视图 |
| `NavigationView` | `UINavigationController` | 导航控制器 |
| `Sheet` | `UIViewController.present` | 模态展示 |

## 组件设计

### 1. 应用生命周期重构

#### AppDelegate.swift
```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 应用启动配置
        return true
    }
    
    // 保持现有的Scene配置方法
}
```

#### SceneDelegate.swift
```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // 创建根视图控制器
        let workSessionVC = WorkSessionViewController()
        let navigationController = UINavigationController(rootViewController: workSessionVC)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}
```

### 2. 主要视图控制器设计

#### WorkSessionViewController
```swift
class WorkSessionViewController: UIViewController {
    // MARK: - Properties
    private let viewModel = WorkSessionViewModel()
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let cameraPreviewView = CameraPreviewView()
    private let postureStatusView = PostureStatusView()
    private let timerDisplayView = TimerDisplayView()
    private let controlsStackView = UIStackView()
    private let primaryActionButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let statsButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        setupNavigationBar()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "HealthyCode"
        
        // 配置滚动视图
        scrollView.showsVerticalScrollIndicator = false
        
        // 配置控件栈视图
        controlsStackView.axis = .horizontal
        controlsStackView.distribution = .fillProportionally
        controlsStackView.spacing = 16
        
        // 配置按钮
        setupButtons()
        
        // 添加子视图
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(cameraPreviewView)
        contentView.addSubview(postureStatusView)
        contentView.addSubview(timerDisplayView)
        contentView.addSubview(controlsStackView)
        
        controlsStackView.addArrangedSubview(primaryActionButton)
        controlsStackView.addArrangedSubview(resetButton)
        controlsStackView.addArrangedSubview(statsButton)
    }
    
    private func setupConstraints() {
        // 使用SnapKit设置约束
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        cameraPreviewView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(200)
        }
        
        postureStatusView.snp.makeConstraints { make in
            make.top.equalTo(cameraPreviewView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        timerDisplayView.snp.makeConstraints { make in
            make.top.equalTo(postureStatusView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        controlsStackView.snp.makeConstraints { make in
            make.top.equalTo(timerDisplayView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
            make.height.equalTo(50)
        }
    }
}
```

### 3. 自定义视图设计

#### TimerDisplayView
```swift
class TimerDisplayView: UIView {
    // MARK: - Properties
    private let containerView = UIView()
    private let timeLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let statusLabel = UILabel()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        
        // 配置容器视图
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        
        // 配置时间标签
        timeLabel.font = .systemFont(ofSize: 48, weight: .bold)
        timeLabel.textAlignment = .center
        timeLabel.textColor = .label
        
        // 配置进度视图
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray5
        progressView.transform = CGAffineTransform(scaleX: 1, y: 2)
        
        // 配置状态标签
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        
        // 添加子视图
        addSubview(containerView)
        containerView.addSubview(timeLabel)
        containerView.addSubview(progressView)
        containerView.addSubview(statusLabel)
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        timeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        progressView.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
    
    // MARK: - Public Methods
    func updateTimer(timeRemaining: TimeInterval, totalTime: TimeInterval, isRunning: Bool) {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        let progress = Float(1.0 - (timeRemaining / totalTime))
        progressView.setProgress(progress, animated: true)
        
        statusLabel.text = isRunning ? "工作中..." : "已暂停"
        statusLabel.textColor = isRunning ? .systemGreen : .systemOrange
    }
}
```

### 4. 数据绑定和状态管理

#### 观察者模式实现
```swift
// 在ViewModel中添加观察者支持
class WorkSessionViewModel: ObservableObject {
    // 使用Combine或通知中心进行数据绑定
    private var cancellables = Set<AnyCancellable>()
    
    // 状态更新回调
    var onStateChanged: ((SessionState) -> Void)?
    var onTimeUpdated: ((TimeInterval, TimeInterval) -> Void)?
    var onPostureChanged: ((PostureType) -> Void)?
    
    // 在状态变化时调用回调
    private func notifyStateChanged() {
        onStateChanged?(sessionState)
    }
    
    private func notifyTimeUpdated() {
        onTimeUpdated?(timeRemaining, getCurrentSettings().workDuration)
    }
}

// 在ViewController中绑定
private func setupBindings() {
    viewModel.onStateChanged = { [weak self] state in
        DispatchQueue.main.async {
            self?.updateUIForState(state)
        }
    }
    
    viewModel.onTimeUpdated = { [weak self] remaining, total in
        DispatchQueue.main.async {
            self?.timerDisplayView.updateTimer(
                timeRemaining: remaining,
                totalTime: total,
                isRunning: self?.viewModel.isRunning ?? false
            )
        }
    }
}
```

### 5. SnapKit约束系统

#### 约束管理策略
```swift
// 基础约束设置
private func setupConstraints() {
    view.snp.makeConstraints { make in
        make.edges.equalToSuperview()
    }
}

// 动态约束更新
private func updateConstraintsForState(_ state: SessionState) {
    switch state {
    case .running:
        controlsStackView.snp.updateConstraints { make in
            make.height.equalTo(60)
        }
    case .idle:
        controlsStackView.snp.updateConstraints { make in
            make.height.equalTo(50)
        }
    }
    
    UIView.animate(withDuration: 0.3) {
        self.view.layoutIfNeeded()
    }
}

// 响应式布局
private func setupResponsiveConstraints() {
    if UIDevice.current.userInterfaceIdiom == .pad {
        // iPad特定约束
        contentView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(600)
            make.centerX.equalToSuperview()
        }
    } else {
        // iPhone约束
        contentView.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
    }
}
```

## 错误处理

### UIKit错误处理模式
```swift
// 错误显示
private func showError(_ error: Error) {
    let alert = UIAlertController(
        title: "错误",
        message: error.localizedDescription,
        preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "确定", style: .default))
    present(alert, animated: true)
}

// 权限处理
private func handleCameraPermission() {
    let alert = UIAlertController(
        title: "摄像头权限",
        message: "需要摄像头权限来检测体态。您可以在设置中启用权限，或选择仅使用计时器功能。",
        preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "设置", style: .default) { _ in
        self.openAppSettings()
    })
    
    alert.addAction(UIAlertAction(title: "仅使用计时器", style: .cancel) { _ in
        self.viewModel.startWorkSession()
    })
    
    present(alert, animated: true)
}
```

## 测试策略

### 单元测试适配
```swift
// UIKit组件测试
class WorkSessionViewControllerTests: XCTestCase {
    var viewController: WorkSessionViewController!
    
    override func setUp() {
        super.setUp()
        viewController = WorkSessionViewController()
        viewController.loadViewIfNeeded()
    }
    
    func testViewLoading() {
        XCTAssertNotNil(viewController.view)
        XCTAssertEqual(viewController.title, "HealthyCode")
    }
    
    func testButtonActions() {
        // 测试按钮响应
        viewController.primaryActionButton.sendActions(for: .touchUpInside)
        // 验证状态变化
    }
}
```

## 性能优化

### 内存管理
- 使用weak引用避免循环引用
- 及时释放不需要的视图和资源
- 优化图像和动画性能

### 布局优化
- 使用SnapKit的优先级系统
- 避免不必要的约束更新
- 使用Auto Layout的intrinsic content size

## 迁移计划

### 阶段1：基础架构
1. 重构AppDelegate和SceneDelegate
2. 创建基础视图控制器结构
3. 集成SnapKit依赖

### 阶段2：核心功能迁移
1. 迁移WorkSessionView到WorkSessionViewController
2. 创建自定义UIView组件
3. 实现数据绑定机制

### 阶段3：完整功能实现
1. 迁移所有剩余视图
2. 实现导航和模态展示
3. 添加动画和过渡效果

### 阶段4：测试和优化
1. 功能完整性测试
2. 性能优化
3. UI/UX调整