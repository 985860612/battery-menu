# CLAUDE.md — Battery Menu

原生 macOS 菜单栏电池健康 / 功率 / 能耗监测工具。纯本机应用：无网络请求、无管理员权限、不上传任何数据。

## 技术栈

- Swift 6 工具链，SwiftUI 菜单栏应用（无 Dock 图标），macOS 13+
- SwiftPM 三 target：`Sources/BatteryCore`（硬件读取/数据模型/本地历史）、`Sources/BatteryMenu`（UI/设置/图表）、`Sources/BatteryDump`（CLI 诊断）

## 常用命令

```bash
swift build                    # 构建
swift build -c release         # Release 构建（提交前必过）
swift run battery-dump         # 输出当前硬件原始快照，排查机型兼容性
swift run BatteryMenu          # 直接跑菜单栏应用
./scripts/build-app.sh         # 组装 dist/Battery Menu.app（临时签名）
```

## 项目约束

- 硬件访问和数据解析只放 `BatteryCore`；界面和偏好只放 `BatteryMenu`。
- 优先使用 macOS 公共 API，IORegistry 兼容逻辑要隔离；缺失字段显示 `—`，**禁止用虚构值填充**。
- 不增加网络依赖、不需要管理员权限的行为；保持「数据仅本机处理」的隐私模型。
- 面向用户的行为变化要**同步更新中英文 README**（`README.md` / `README.zh-CN.md`）。
- 不提交 `.build/`、`dist/` 构建产物。
- Issue / commit / `battery-dump` 输出中不得包含序列号、设备标识、用户名或完整 IORegistry 数据。
- 详细 PR 检查清单见 [CONTRIBUTING.zh-CN.md](CONTRIBUTING.zh-CN.md)。
