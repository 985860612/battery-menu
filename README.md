# Battery Menu

原生 macOS 菜单栏电池监测工具，读取并展示：

- 当前电量、供电来源与充电状态
- 电池温度、最大容量、健康状态和循环次数
- 适配器名称、额定功率、电压和实时输入电流
- 适配器输入、系统负载与电池功率遥测
- 最近 30 分钟功率曲线，记录会在应用重启后保留
- 跟随系统、浅色和深色三种主题
- 使用 macOS POWER 指标估算并展示当前高耗能 App
- 原生设置窗口，可分别显示或隐藏各个信息模块
- 菜单栏可分别显示电池图标、电量、温度和系统功率

所有数据均在本机读取，不联网、不修改充电设置，也不需要管理员权限。

## 运行

```bash
cd battery-menu
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open "dist/Battery Menu.app"
```

运行后，应用只出现在 macOS 菜单栏，不显示 Dock 图标。

## 查看原始快照

```bash
swift run battery-dump
```

## 开发检查

```bash
swift build
swift run battery-dump
```

## 数据说明

- 常规电量与供电状态来自 IOKit Power Sources API。
- 温度、循环次数、适配器与实时功率来自 `AppleSmartBattery` IORegistry。
- 最大容量由 `system_profiler -json SPPowerDataType` 低频读取，与系统设置中的显示值保持一致。
- 不同 Mac 机型可能不发布全部遥测字段，界面会对缺失值显示 `—`。
