import AppKit
import BatteryCore
import Charts
import SwiftUI

private enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "跟随系统"
        case .light: "浅色"
        case .dark: "深色"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct MenuBarLabel: View {
    let snapshot: BatterySnapshot
    @AppStorage("menubar.icon") private var showIcon = true
    @AppStorage("menubar.percentage") private var showPercentage = true
    @AppStorage("menubar.temperature") private var showTemperature = false
    @AppStorage("menubar.power") private var showPower = false

    var body: some View {
        HStack(spacing: 4) {
            if showIcon || !hasVisibleContent {
                Image(systemName: batterySymbol)
                    .symbolRenderingMode(.hierarchical)

                if snapshot.chargeState == .charging {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                }
            }

            if showPercentage {
                Text("\(snapshot.percentage)%")
                    .monospacedDigit()
            }

            if showTemperature, let temperature = snapshot.temperatureCelsius {
                Text("\(Int(temperature.rounded()))°")
                    .monospacedDigit()
            }

            if showPower, let watts = snapshot.systemLoadWatts {
                Text("\(Int(watts.rounded()))W")
                    .monospacedDigit()
            }
        }
        .accessibilityLabel("电池电量 \(snapshot.percentage)%")
    }

    private var hasVisibleContent: Bool {
        showIcon || showPercentage || showTemperature || showPower
    }

    private var batterySymbol: String {
        let level: Int
        switch snapshot.percentage {
        case ..<13: level = 0
        case ..<38: level = 25
        case ..<63: level = 50
        case ..<88: level = 75
        default: level = 100
        }
        return "battery.\(level)percent"
    }
}

struct BatteryPanel: View {
    @ObservedObject var store: BatteryStore
    @Environment(\.colorScheme) private var inheritedColorScheme
    @AppStorage("appearance") private var appearance = AppAppearance.system.rawValue
    @AppStorage("module.charge") private var showCharge = true
    @AppStorage("module.health") private var showHealth = true
    @AppStorage("module.power") private var showPower = true
    @AppStorage("module.history") private var showHistory = true
    @AppStorage("module.apps") private var showApps = true
    @AppStorage("module.adapter") private var showAdapter = true

    private var battery: BatterySnapshot { store.snapshot }
    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearance) ?? .system
    }
    private var resolvedColorScheme: ColorScheme {
        selectedAppearance.colorScheme ?? inheritedColorScheme
    }
    private var accentColor: Color {
        resolvedColorScheme == .light
            ? Color(red: 0.02, green: 0.43, blue: 0.17)
            : Color(red: 0.20, green: 0.84, blue: 0.36)
    }
    private var warningColor: Color {
        resolvedColorScheme == .light
            ? Color(red: 0.65, green: 0.25, blue: 0.02)
            : Color(red: 1.00, green: 0.62, blue: 0.04)
    }
    private var dangerColor: Color {
        resolvedColorScheme == .light
            ? Color(red: 0.70, green: 0.08, blue: 0.08)
            : Color(red: 1.00, green: 0.27, blue: 0.23)
    }
    private var chartBlue: Color {
        resolvedColorScheme == .light
            ? Color(red: 0.00, green: 0.35, blue: 0.68)
            : Color(red: 0.39, green: 0.82, blue: 1.00)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                            .padding(.top, 16)
                            .id("panel-top")
                        if showCharge { chargeSection }
                        if showHealth { healthSection }
                        if showPower { powerSection }
                        if showHistory { historySection }
                        if showApps { appUsageSection }
                        if showAdapter { adapterSection }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .onAppear {
                    proxy.scrollTo("panel-top", anchor: .top)
                }
            }

            footer
        }
        .frame(width: 370, height: 560)
        .background {
            MacVisualEffectView(
                material: .popover,
                blendingMode: .behindWindow
            )
            .ignoresSafeArea()
        }
        .background {
            WindowAppearanceBridge(appearance: selectedAppearance)
        }
        .tint(accentColor)
        .accentColor(accentColor)
        .environment(\.colorScheme, resolvedColorScheme)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.14))
                Image(systemName: statusSymbol)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(accentColor)
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if let temperature = battery.temperatureCelsius {
                VStack(alignment: .trailing, spacing: 2) {
                    Label {
                        Text(temperature, format: .number.precision(.fractionLength(1)))
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "thermometer.medium")
                    }
                    .font(.headline)
                    .foregroundStyle(temperatureColor(temperature))

                    Text("°C")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var chargeSection: some View {
        NativeSection {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(chargeStateText, systemImage: chargeStateSymbol)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(battery.percentage)%")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .monospacedDigit()
                }

                ProgressView(value: Double(battery.percentage), total: 100)
                    .progressViewStyle(.linear)
                    .controlSize(.small)

                HStack {
                    Text(adapterElectricalText)
                    Spacer()
                    Text("当前电量")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var healthSection: some View {
        NativeSection {
            HStack(spacing: 0) {
                Metric(
                    symbol: "heart.text.square",
                    value: battery.healthPercentage.map { "\($0)%" } ?? "—",
                    label: "最大容量"
                )

                Divider().frame(height: 52)

                Metric(
                    symbol: "arrow.triangle.2.circlepath",
                    value: battery.cycleCount.map(String.init) ?? "—",
                    label: "循环次数"
                )

                Divider().frame(height: 52)

                Metric(
                    symbol: battery.powerSource == .adapter ? "powerplug" : "clock",
                    value: remainingText,
                    label: battery.powerSource == .adapter ? "当前状态" : "预计可用"
                )
            }
        }
    }

    private var powerSection: some View {
        NativeSection {
            VStack(alignment: .leading, spacing: 0) {
                SectionTitle("实时功率", symbol: "bolt.horizontal.circle")
                    .padding(.bottom, 8)

                PowerRow(
                    symbol: "powerplug",
                    title: "电源输出",
                    value: wattsText(adapterOutputWatts),
                    active: adapterOutputWatts > 0
                )

                Divider().padding(.leading, 27)

                PowerRow(
                    symbol: "battery.100",
                    title: "电池输出",
                    value: wattsText(batteryOutputWatts),
                    active: batteryOutputWatts > 0
                )

                Divider().padding(.leading, 27)

                PowerRow(
                    symbol: "laptopcomputer",
                    title: "系统负载",
                    value: wattsText(battery.systemLoadWatts),
                    active: true
                )
            }
        }
    }

    private var adapterSection: some View {
        NativeSection {
            VStack(alignment: .leading, spacing: 0) {
                SectionTitle("适配器", symbol: "powerplug.fill")
                    .padding(.bottom, 8)

                NativeInfoRow(label: "名称", value: adapterName)
                Divider()
                NativeInfoRow(
                    label: "额定功率",
                    value: battery.adapterRatedWatts.map { "\($0) W" } ?? "—"
                )
                Divider()
                NativeInfoRow(label: "实时输入", value: wattsText(battery.adapterInputWatts))
            }
        }
    }

    private var appUsageSection: some View {
        NativeSection {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionTitle("当前高耗能 App", symbol: "gauge.with.dots.needle.67percent")
                    Spacer()
                    Text("实时能耗影响")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if store.appUsage.isEmpty {
                    Text("暂无可用的 App 活动数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                } else {
                    VStack(spacing: 9) {
                        ForEach(Array(store.appUsage.enumerated()), id: \.element.id) { index, usage in
                            AppUsageRow(
                                rank: index + 1,
                                usage: usage,
                                maximumImpact: store.appUsage.first?.energyImpact ?? 1
                            )
                        }
                    }
                }
            }
        }
    }

    private var historySection: some View {
        NativeSection {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionTitle("功率曲线", symbol: "chart.xyaxis.line")
                    Spacer()
                    Text("最近 30 分钟")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Button {
                        store.clearPowerHistory()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("清除功率记录")
                }

                ZStack {
                    Chart(store.powerHistory) { sample in
                        LineMark(
                            x: .value("时间", sample.timestamp),
                            y: .value("功率", sample.systemWatts)
                        )
                        .foregroundStyle(by: .value("来源", "系统"))
                        .lineStyle(StrokeStyle(lineWidth: 2.4))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("时间", sample.timestamp),
                            y: .value("功率", sample.adapterWatts)
                        )
                        .foregroundStyle(by: .value("来源", "电源"))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("时间", sample.timestamp),
                            y: .value("功率", sample.batteryWatts)
                        )
                        .foregroundStyle(by: .value("来源", "电池"))
                        .lineStyle(StrokeStyle(lineWidth: 1.8, dash: [2, 3]))
                        .interpolationMethod(.catmullRom)
                    }
                    .chartForegroundStyleScale([
                        "电源": accentColor,
                        "电池": chartBlue,
                        "系统": warningColor
                    ])
                    .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 3)) {
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.hour().minute())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    .chartYScale(domain: .automatic(includesZero: true))
                    .frame(height: 150)

                    if store.powerHistory.count < 2 {
                        Text("正在记录功率…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 10) {
                Text("Battery Menu")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(battery.sampledAt, format: .dateTime.hour().minute().second())
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)

                Button {
                    store.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("刷新")

                settingsControl

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("退出")
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(.ultraThinMaterial)
        }
    }

    private var title: String {
        switch battery.powerSource {
        case .adapter: "电源已连接"
        case .battery: "正在使用电池"
        case .unknown: "未检测到电池"
        }
    }

    private var subtitle: String {
        switch battery.chargeState {
        case .charging: "电池正在充电"
        case .paused: "已接通电源，当前未充电"
        case .discharging: "电池正在放电"
        case .full: "电池已充满"
        case .unknown: "正在读取电池状态"
        }
    }

    private var statusSymbol: String {
        switch battery.powerSource {
        case .adapter: "powerplug.fill"
        case .battery: "battery.100"
        case .unknown: "exclamationmark.triangle"
        }
    }

    private var chargeStateSymbol: String {
        switch battery.chargeState {
        case .charging: "bolt.fill"
        case .paused: "pause.circle"
        case .discharging: "battery.100"
        case .full: "checkmark.circle"
        case .unknown: "questionmark.circle"
        }
    }

    private var chargeStateText: String {
        switch battery.chargeState {
        case .charging: "正在充电"
        case .paused: "充电已暂停"
        case .discharging: "正在放电"
        case .full: "电池已充满"
        case .unknown: "状态未知"
        }
    }

    private var adapterElectricalText: String {
        guard let voltage = battery.adapterVoltageVolts,
              let current = battery.adapterCurrentAmps
        else {
            return battery.powerSource == .adapter ? "正在读取适配器参数" : "未连接电源"
        }
        return String(format: "%.1f V · %.2f A", voltage, current)
    }

    private var adapterName: String {
        if let name = battery.adapterName {
            return name
        }
        return battery.powerSource == .adapter ? "USB-C 电源适配器" : "未连接"
    }

    private var remainingText: String {
        if battery.powerSource == .adapter {
            return battery.chargeState == .charging ? "充电中" : "未充电"
        }
        guard let minutes = battery.timeRemainingMinutes else { return "估算中" }
        return "\(minutes / 60)时\(minutes % 60)分"
    }

    private var adapterOutputWatts: Double {
        battery.powerSource == .adapter ? (battery.adapterInputWatts ?? 0) : 0
    }

    private var batteryOutputWatts: Double {
        guard battery.powerSource == .battery else { return 0 }
        if let batteryWatts = battery.batteryWatts, abs(batteryWatts) >= 0.01 {
            return abs(batteryWatts)
        }
        return battery.systemLoadWatts ?? 0
    }

    private func wattsText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.2f W", value)
    }

    private func temperatureColor(_ value: Double) -> Color {
        if value >= 42 { return dangerColor }
        if value >= 38 { return warningColor }
        return accentColor
    }

    @ViewBuilder
    private var settingsControl: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("设置")
        } else {
            Button {
                let opened = NSApp.sendAction(
                    Selector(("showSettingsWindow:")),
                    to: nil,
                    from: nil
                )
                if !opened {
                    NSApp.sendAction(
                        Selector(("showPreferencesWindow:")),
                        to: nil,
                        from: nil
                    )
                }
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("设置")
        }
    }
}

struct BatterySettingsView: View {
    @AppStorage("appearance") private var appearance = AppAppearance.system.rawValue
    @AppStorage("menubar.icon") private var showMenuBarIcon = true
    @AppStorage("menubar.percentage") private var showMenuBarPercentage = true
    @AppStorage("menubar.temperature") private var showMenuBarTemperature = false
    @AppStorage("menubar.power") private var showMenuBarPower = false
    @AppStorage("module.charge") private var showCharge = true
    @AppStorage("module.health") private var showHealth = true
    @AppStorage("module.power") private var showPower = true
    @AppStorage("module.history") private var showHistory = true
    @AppStorage("module.apps") private var showApps = true
    @AppStorage("module.adapter") private var showAdapter = true

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearance) ?? .system
    }

    var body: some View {
        Form {
            Section("外观") {
                Picker("主题", selection: $appearance) {
                    ForEach(AppAppearance.allCases) { option in
                        Label(option.title, systemImage: option.symbol)
                            .tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("菜单栏显示") {
                ModuleToggle(
                    title: "电池图标",
                    symbol: "battery.75percent",
                    isOn: $showMenuBarIcon
                )
                ModuleToggle(
                    title: "电量百分比",
                    symbol: "percent",
                    isOn: $showMenuBarPercentage
                )
                ModuleToggle(
                    title: "电池温度",
                    symbol: "thermometer.medium",
                    isOn: $showMenuBarTemperature
                )
                ModuleToggle(
                    title: "系统功率",
                    symbol: "bolt",
                    isOn: $showMenuBarPower
                )
            }

            Section("显示模块") {
                ModuleToggle(
                    title: "充电概览",
                    symbol: "battery.100",
                    isOn: $showCharge
                )
                ModuleToggle(
                    title: "电池健康",
                    symbol: "heart.text.square",
                    isOn: $showHealth
                )
                ModuleToggle(
                    title: "实时功率",
                    symbol: "bolt.horizontal.circle",
                    isOn: $showPower
                )
                ModuleToggle(
                    title: "功率曲线",
                    symbol: "chart.xyaxis.line",
                    isOn: $showHistory
                )
                ModuleToggle(
                    title: "高耗能 App",
                    symbol: "gauge.with.dots.needle.67percent",
                    isOn: $showApps
                )
                ModuleToggle(
                    title: "适配器信息",
                    symbol: "powerplug",
                    isOn: $showAdapter
                )
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 560)
        .preferredColorScheme(selectedAppearance.colorScheme)
    }
}

private struct ModuleToggle: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: symbol)
                .symbolRenderingMode(.hierarchical)
        }
    }
}

private struct WindowAppearanceBridge: NSViewRepresentable {
    let appearance: AppAppearance

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        apply(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        apply(to: nsView)
    }

    private func apply(to view: NSView) {
        DispatchQueue.main.async {
            view.window?.isOpaque = false
            view.window?.backgroundColor = .clear

            switch appearance {
            case .system:
                view.window?.appearance = nil
            case .light:
                view.window?.appearance = NSAppearance(named: .aqua)
            case .dark:
                view.window?.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
}

private struct MacVisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
        nsView.isEmphasized = true
    }
}

private struct NativeSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.thinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
            }
    }
}

private struct SectionTitle: View {
    let title: String
    let symbol: String

    init(_ title: String, symbol: String) {
        self.title = title
        self.symbol = symbol
    }

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .symbolRenderingMode(.hierarchical)
    }
}

private struct Metric: View {
    let symbol: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .monospacedDigit()

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PowerRow: View {
    let symbol: String
    let title: String
    let value: String
    let active: Bool

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .frame(width: 18)
                .foregroundStyle(active ? Color.accentColor : Color.secondary)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(active ? Color.accentColor : Color.secondary)
                .monospacedDigit()
        }
        .frame(height: 32)
    }
}

private struct NativeInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        LabeledContent(label) {
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
                .monospacedDigit()
        }
        .font(.caption)
        .frame(height: 29)
    }
}

private struct AppUsageRow: View {
    let rank: Int
    let usage: AppUsageSample
    let maximumImpact: Double
    @Environment(\.colorScheme) private var colorScheme

    private var icon: NSImage {
        NSWorkspace.shared.icon(forFile: usage.appPath)
    }
    private var leadingColor: Color {
        colorScheme == .light
            ? Color(red: 0.65, green: 0.25, blue: 0.02)
            : Color(red: 1.00, green: 0.62, blue: 0.04)
    }

    var body: some View {
        HStack(spacing: 9) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(rank)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 12, alignment: .leading)

                    Text(usage.name)
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer()

                    Text(usage.energyImpact, format: .number.precision(.fractionLength(1)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ProgressView(
                    value: usage.energyImpact,
                    total: max(maximumImpact, 1)
                )
                .progressViewStyle(.linear)
                .controlSize(.mini)
                .tint(rank == 1 ? leadingColor : .accentColor)
            }
        }
    }
}
