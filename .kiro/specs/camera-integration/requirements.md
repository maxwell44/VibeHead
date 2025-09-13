# Requirements Document

## Introduction

本功能将在WorkSessionViewController中集成摄像头预览功能。当用户点击开始工作按钮时，原本显示静态图片的centerImageView将切换为实时摄像头预览，为后续的体态检测功能提供视觉输入。该功能将复用CameraTestViewController中已验证的摄像头集成方案，确保在圆形容器中正确显示前置摄像头画面。

## Requirements

### Requirement 1

**User Story:** 作为用户，我希望在开始工作会话时能够看到摄像头预览，以便确认摄像头正常工作并为体态检测做准备。

#### Acceptance Criteria

1. WHEN 用户点击"开始工作"按钮 THEN 系统 SHALL 将centerImageView从静态图片切换为摄像头预览
2. WHEN 摄像头预览启动 THEN 系统 SHALL 显示前置摄像头的实时画面
3. WHEN 摄像头预览显示 THEN 系统 SHALL 保持280x280像素的圆形显示区域
4. WHEN 工作会话结束或重置 THEN 系统 SHALL 将摄像头预览切换回静态图片

### Requirement 2

**User Story:** 作为用户，我希望摄像头预览能够正确处理权限和错误情况，以便在各种设备状态下都能获得良好的用户体验。

#### Acceptance Criteria

1. WHEN 摄像头权限未授权 THEN 系统 SHALL 显示权限请求对话框
2. WHEN 用户拒绝摄像头权限 THEN 系统 SHALL 继续显示静态图片并允许仅计时器模式
3. WHEN 摄像头初始化失败 THEN 系统 SHALL 显示错误提示并回退到静态图片
4. WHEN 摄像头会话中断 THEN 系统 SHALL 自动尝试恢复或显示错误状态

### Requirement 3

**User Story:** 作为用户，我希望摄像头预览的视觉效果与现有UI设计保持一致，以便获得统一的用户界面体验。

#### Acceptance Criteria

1. WHEN 摄像头预览显示 THEN 系统 SHALL 保持与CameraTestViewController相同的圆形裁剪效果
2. WHEN 摄像头预览显示 THEN 系统 SHALL 使用resizeAspectFill填充模式确保画面充满圆形区域
3. WHEN 摄像头预览显示 THEN 系统 SHALL 正确设置视频方向避免画面旋转问题
4. WHEN 切换摄像头状态 THEN 系统 SHALL 提供平滑的过渡动画效果

### Requirement 4

**User Story:** 作为开发者，我希望摄像头集成代码具有良好的架构和可维护性，以便后续扩展体态检测等功能。

#### Acceptance Criteria

1. WHEN 实现摄像头功能 THEN 系统 SHALL 复用CameraTestViewController中已验证的摄像头设置代码
2. WHEN 管理摄像头会话 THEN 系统 SHALL 在适当的生命周期方法中启动和停止摄像头
3. WHEN 处理摄像头状态 THEN 系统 SHALL 使用清晰的状态管理避免内存泄漏
4. WHEN 集成摄像头功能 THEN 系统 SHALL 保持与现有WorkSessionViewModel的兼容性