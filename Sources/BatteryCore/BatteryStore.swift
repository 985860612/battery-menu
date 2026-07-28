import Foundation

@MainActor
public final class BatteryStore: ObservableObject {
    @Published public private(set) var snapshot: BatterySnapshot
    @Published public private(set) var powerHistory: [PowerSample]
    @Published public private(set) var appUsage: [AppUsageSample]

    private var health: BatteryHealth
    private var timer: Timer?
    private var healthRefreshCounter = 0
    private var historySaveCounter = 0
    private var appUsageRefreshCounter = 0
    private var isRefreshingAppUsage = false
    private let historyDuration: TimeInterval = 30 * 60

    public init() {
        health = BatteryReader.readSystemHealth()
        snapshot = BatteryReader.readSnapshot(health: health)
        powerHistory = PowerHistoryStore.load()
        appUsage = []
        recordPowerSample()
        refreshAppUsage()
        start()
    }

    public func refresh() {
        healthRefreshCounter += 1
        // Health changes slowly; avoid launching system_profiler every two seconds.
        if healthRefreshCounter >= 150 {
            health = BatteryReader.readSystemHealth()
            healthRefreshCounter = 0
        }
        snapshot = BatteryReader.readSnapshot(health: health)
        recordPowerSample()

        appUsageRefreshCounter += 1
        if appUsageRefreshCounter >= 2 {
            refreshAppUsage()
            appUsageRefreshCounter = 0
        }
    }

    public func clearPowerHistory() {
        powerHistory = []
        recordPowerSample(forceSave: true)
    }

    private func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        timer?.tolerance = 0.25
    }

    private func recordPowerSample(forceSave: Bool = false) {
        let adapter = snapshot.powerSource == .adapter
            ? sanitized(snapshot.adapterInputWatts)
            : 0

        let battery: Double
        if snapshot.powerSource == .battery {
            let measured = abs(snapshot.batteryWatts ?? 0)
            battery = measured >= 0.01
                ? sanitized(measured)
                : sanitized(snapshot.systemLoadWatts)
        } else {
            battery = 0
        }

        powerHistory.append(
            PowerSample(
                timestamp: snapshot.sampledAt,
                adapterWatts: adapter,
                batteryWatts: battery,
                systemWatts: sanitized(snapshot.systemLoadWatts)
            )
        )

        let cutoff = Date().addingTimeInterval(-historyDuration)
        powerHistory.removeAll { $0.timestamp < cutoff }

        historySaveCounter += 1
        if forceSave || historySaveCounter >= 15 {
            PowerHistoryStore.save(powerHistory)
            historySaveCounter = 0
        }
    }

    private func sanitized(_ value: Double?) -> Double {
        max(0, min(500, value ?? 0))
    }

    private func refreshAppUsage() {
        guard !isRefreshingAppUsage else { return }
        isRefreshingAppUsage = true

        Task {
            let result = await Task.detached(priority: .utility) {
                AppUsageReader.readTopApps()
            }.value
            appUsage = result
            isRefreshingAppUsage = false
        }
    }
}

private enum PowerHistoryStore {
    private static var fileURL: URL? {
        guard let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        return base
            .appendingPathComponent("Battery Menu", isDirectory: true)
            .appendingPathComponent("power-history.json")
    }

    static func load() -> [PowerSample] {
        guard let fileURL,
              let data = try? Data(contentsOf: fileURL),
              let samples = try? JSONDecoder().decode([PowerSample].self, from: data)
        else {
            return []
        }

        let now = Date()
        let cutoff = now.addingTimeInterval(-30 * 60)
        return samples.filter {
            $0.timestamp >= cutoff && $0.timestamp <= now.addingTimeInterval(60)
        }
    }

    static func save(_ samples: [PowerSample]) {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            let data = try encoder.encode(samples)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // History is optional telemetry; a write failure must not affect
            // live battery monitoring.
        }
    }
}
