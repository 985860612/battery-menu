# 参与 Battery Menu 开发

[English](CONTRIBUTING.md) · [简体中文](CONTRIBUTING.zh-CN.md)

感谢你帮助改进 Battery Menu。不同 Mac 机型提供的硬件遥测数据存在差异，
因此兼容性反馈和范围明确的修复尤其有价值。
提交贡献即表示你同意该贡献可以按照项目的 [MIT License](LICENSE) 分发。

## 开始之前

- 新建 Issue 前先搜索是否已有相同问题。
- 修改范围保持聚焦，避免夹带无关的格式化改动。
- Issue 和提交中不要包含序列号、设备标识、用户名或完整 IORegistry 数据。
- 报告遥测问题时，请说明 Mac 机型和 macOS 版本。

## 本地开发

```bash
git clone https://github.com/985860612/battery-menu.git
cd battery-menu
swift build
swift run battery-dump
```

组装应用包：

```bash
./scripts/build-app.sh
open "dist/Battery Menu.app"
```

## Pull Request 检查清单

- `swift build -c release` 可以完成 Release 构建。
- `./scripts/build-app.sh` 可以生成有效的应用包。
- 新增遥测字段不可用时能够安全回退为 `nil` 或 `—`。
- 界面修改在跟随系统、浅色和深色外观下均可正常使用。
- 面向用户的行为和硬件限制已同步更新中英文 README。
- 不提交 `.build/` 或 `dist/` 中的构建产物。

## 项目约定

- 硬件访问和数据解析放在 `BatteryCore`。
- 界面和偏好设置放在 `BatteryMenu`。
- 优先使用 macOS 公共 API，并隔离 IORegistry 兼容逻辑。
- 不增加网络依赖或需要管理员权限的行为。
- 保持应用数据仅在本机处理的隐私模型。

提交 Bug 时，请提供复现步骤、预期与实际结果；如果需要附带
`battery-dump` 输出，请先移除可能识别设备或用户的信息。
