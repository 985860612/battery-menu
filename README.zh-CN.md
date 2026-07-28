<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="Battery Menu 应用图标">
</p>

<h1 align="center">Battery Menu</h1>

<p align="center">
  原生 macOS 菜单栏电池健康、功率流向与能耗监测工具。
</p>

<p align="center">
  <a href="README.md">English</a> · <strong>简体中文</strong>
</p>

Battery Menu 读取 macOS 本机硬件遥测数据，并通过紧凑、可配置的菜单栏面板进行展示。
所有数据均保留在本机；应用不会连接服务器、修改充电行为，也不需要管理员权限。

## 功能

- 展示电量、充电状态、供电来源、温度、健康度和循环次数
- 展示适配器名称、额定功率、电压、电流与实时输入功率
- 分别展示电源输出、电池输出和估算的系统负载
- 持久保存最近 30 分钟功率曲线
- 使用 macOS `POWER` 指标估算当前高耗能 App
- 菜单栏可配置电池图标、电量、温度和功率
- 可分别显示或隐藏充电、健康、功率、曲线、App 和适配器模块
- 支持跟随系统、浅色和深色外观，以及原生 macOS 材质
- 使用原生 SwiftUI 菜单栏体验，不显示 Dock 图标

## 系统要求

- macOS 13 Ventura 或更高版本
- macOS 能够发布电池遥测数据的 Apple 芯片或 Intel Mac
- 从源码构建时需要 Swift 6 工具链

不同 Mac 机型和 macOS 版本提供的硬件字段可能不同。缺失数据会显示为 `—`，
不会使用虚构值填充。

## 安装

### 下载 Release

前往 [GitHub Releases](https://github.com/985860612/battery-menu/releases)
下载最新安装包，解压后将 `Battery Menu.app` 移入 `/Applications`。

当前 Release 使用临时签名，尚未经过 Apple 公证。如果 macOS 首次启动时阻止应用，
请打开“系统设置 → 隐私与安全”，明确允许该应用运行。

### 从源码构建

```bash
git clone https://github.com/985860612/battery-menu.git
cd battery-menu
./scripts/build-app.sh
open "dist/Battery Menu.app"
```

构建脚本会编译 Release 二进制、组装应用包、复制应用图标并执行临时签名。

## 使用

启动应用后，点击菜单栏中的电池项目打开面板。通过面板底部的设置按钮可以切换外观、
显示或隐藏模块，并配置菜单栏展示内容。

功率曲线保存在本机：

```text
~/Library/Application Support/Battery Menu/power-history.json
```

可以通过功率曲线右上角的清除按钮删除记录。

## 数据来源

| 数据 | macOS 来源 | 说明 |
| --- | --- | --- |
| 电量与充电状态 | IOKit Power Sources API | macOS 标准电源数据 |
| 温度、循环、适配器与功率 | IORegistry 中的 `AppleSmartBattery` | 可用字段因硬件而异 |
| 最大容量 | `system_profiler -json SPPowerDataType` | 低频刷新 |
| 高耗能 App | `/usr/bin/top` 的 `POWER` 采样 + `/bin/ps` | 实时估算，不是活动监视器的 12 小时历史 |

## 隐私

- 不发起网络请求
- 不上传分析数据或遥测信息
- 不需要管理员权限
- 不修改充电上限或系统电源管理
- 仅在本机持久保存最近 30 分钟功率曲线

## 开发

```bash
swift build
swift run battery-dump
swift run BatteryMenu
```

`battery-dump` 会输出当前原始快照，可用于排查不同硬件的兼容性。

```text
Sources/BatteryCore/   硬件读取、数据模型与本地历史
Sources/BatteryMenu/   菜单栏应用、面板、设置与图表
Sources/BatteryDump/   命令行诊断工具
Resources/             应用图标源图与 macOS 图标文件
Support/               应用包元数据
scripts/               Release 应用包构建脚本
```

提交修改前请阅读 [CONTRIBUTING.zh-CN.md](CONTRIBUTING.zh-CN.md)。

## 已知限制

- 硬件遥测依赖 macOS 接口，Apple 并未保证所有 Mac 机型提供完全一致的数据。
- 高耗能 App 数值来自短时实时采样，不能直接与活动监视器的 12 小时能耗列比较。
- Release 尚未使用 Apple Developer ID 签名或完成公证。

## 开源协议

Battery Menu 使用 [MIT License](LICENSE) 开源。

Copyright (c) 2026 wangxiaojie
