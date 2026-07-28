import Foundation
import IOKit
import IOKit.ps

public struct BatteryHealth: Sendable, Equatable {
    public let percentage: Int?
    public let condition: String?

    public init(percentage: Int?, condition: String?) {
        self.percentage = percentage
        self.condition = condition
    }
}

public enum BatteryReader {
    public static func readSnapshot(health: BatteryHealth? = nil) -> BatterySnapshot {
        let powerSource = readPowerSource()
        let registry = readSmartBatteryRegistry()
        let packRegistry = readRegistryService(named: "AppleSmartBatteryPack")
        let packBatteryData = dictionary(packRegistry["BatteryData"])
        let batteryData = packBatteryData.isEmpty
            ? dictionary(registry["BatteryData"])
            : packBatteryData
        let telemetry = dictionary(registry["PowerTelemetryData"])
        let distribution = dictionary(registry["PowerDistribution"])
        let adapter = dictionary(registry["AdapterDetails"])

        let percentage = integer(powerSource["Current Capacity"])
            ?? integer(registry["CurrentCapacity"])
            ?? integer(batteryData["CurrentCapacity"])
            ?? 0

        let externalConnected = boolean(registry["ExternalConnected"])
            ?? (string(powerSource["Power Source State"]) == "AC Power")
        let isCharging = boolean(registry["IsCharging"])
            ?? boolean(powerSource["Is Charging"])
            ?? false
        let fullyCharged = boolean(registry["FullyCharged"])
            ?? boolean(powerSource["Is Charged"])
            ?? false

        let source: BatterySnapshot.PowerSource = if externalConnected {
            .adapter
        } else if !registry.isEmpty || !powerSource.isEmpty {
            .battery
        } else {
            .unknown
        }

        let chargeState: BatterySnapshot.ChargeState = if isCharging {
            .charging
        } else if fullyCharged {
            .full
        } else if externalConnected {
            .paused
        } else if source == .battery {
            .discharging
        } else {
            .unknown
        }

        let temperature = batteryTemperature(
            nestedBatteryData: batteryData,
            registry: registry
        )

        let rawHealth = calculatedHealth(batteryData: batteryData, registry: registry)
        let inputMilliwatts = double(telemetry["SystemPowerIn"])
        let systemMilliwatts = double(telemetry["SystemLoad"])
        let batteryMilliwatts = double(telemetry["BatteryPower"])

        let voltageMillivolts = double(distribution["IPDInputVoltage"])
            ?? double(adapter["AdapterVoltage"])
        let rawInputWatts = watts(fromMilliwatts: inputMilliwatts)
        let systemLoadWatts = watts(fromMilliwatts: systemMilliwatts)
        let inputWatts: Double? = if source == .adapter,
                                    (rawInputWatts ?? 0) < 0.01,
                                    let systemLoadWatts {
            // During adapter renegotiation SystemPowerIn can briefly reset to
            // zero while SystemLoad remains valid.
            systemLoadWatts
        } else {
            rawInputWatts
        }
        let voltageVolts = voltageMillivolts.map { $0 / 1_000 }
        let currentAmps: Double? = if let inputWatts, let voltageVolts, voltageVolts > 0 {
            inputWatts / voltageVolts
        } else {
            nil
        }

        return BatterySnapshot(
            percentage: max(0, min(100, percentage)),
            powerSource: source,
            chargeState: chargeState,
            temperatureCelsius: temperature,
            healthPercentage: health?.percentage ?? rawHealth,
            healthCondition: localizedCondition(health?.condition),
            cycleCount: integer(registry["CycleCount"]) ?? integer(batteryData["CycleCount"]),
            designCycleCount: integer(registry["DesignCycleCount9C"]),
            timeRemainingMinutes: timeRemainingMinutes(source: source),
            adapterName: string(adapter["Name"]),
            adapterRatedWatts: integer(adapter["Watts"]),
            adapterVoltageVolts: voltageVolts,
            adapterCurrentAmps: currentAmps,
            adapterInputWatts: inputWatts,
            systemLoadWatts: systemLoadWatts,
            batteryWatts: watts(fromMilliwatts: batteryMilliwatts),
            sampledAt: Date()
        )
    }

    /// `system_profiler` provides the same maximum-capacity percentage shown in
    /// System Settings. It is intentionally sampled infrequently by the app.
    public static func readSystemHealth() -> BatteryHealth {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["-json", "SPPowerDataType"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0,
                  let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = root["SPPowerDataType"] as? [[String: Any]],
                  let item = items.first,
                  let health = item["sppower_battery_health_info"] as? [String: Any]
            else {
                return BatteryHealth(percentage: nil, condition: nil)
            }

            let percentageText = health["sppower_battery_health_maximum_capacity"] as? String
            let percentage = percentageText.flatMap {
                Int($0.trimmingCharacters(in: CharacterSet.decimalDigits.inverted))
            }
            let condition = health["sppower_battery_health"] as? String
            return BatteryHealth(percentage: percentage, condition: condition)
        } catch {
            return BatteryHealth(percentage: nil, condition: nil)
        }
    }

    public static func batteryTemperature(
        nestedBatteryData: [String: Any],
        registry: [String: Any]
    ) -> Double? {
        // Apple silicon publishes hundredths of a Celsius degree in BatteryData.
        if let raw = double(nestedBatteryData["Temperature"])
            ?? double(nestedBatteryData["VirtualTemperature"]),
           raw > 0 {
            return raw / 100
        }

        // Older Intel models commonly publish tenths of a Kelvin at the root.
        if let raw = double(registry["Temperature"])
            ?? double(registry["VirtualTemperature"]),
           raw > 0 {
            let celsius = (raw / 10) - 273.15
            return (-20...100).contains(celsius) ? celsius : raw / 100
        }
        return nil
    }

    public static func calculatedHealth(
        batteryData: [String: Any],
        registry: [String: Any]
    ) -> Int? {
        let full = double(batteryData["AppleRawMaxCapacity"])
            ?? double(batteryData["FullChargeCapacity"])
            ?? double(registry["AppleRawMaxCapacity"])
        let design = double(batteryData["DesignCapacity"])
            ?? double(registry["DesignCapacity"])

        guard let full, let design, design > 0 else { return nil }
        return max(0, min(100, Int((full / design * 100).rounded())))
    }

    private static func readPowerSource() -> [String: Any] {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return [:]
        }

        for source in sources {
            if let description = IOPSGetPowerSourceDescription(info, source)?
                .takeUnretainedValue() as? [String: Any],
               description["Type"] as? String == "InternalBattery" {
                return description
            }
        }
        return [:]
    }

    private static func readSmartBatteryRegistry() -> [String: Any] {
        readRegistryService(named: "AppleSmartBattery")
    }

    private static func readRegistryService(named serviceName: String) -> [String: Any] {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching(serviceName)
        )
        guard service != IO_OBJECT_NULL else { return [:] }
        defer { IOObjectRelease(service) }

        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(
            service,
            &properties,
            kCFAllocatorDefault,
            0
        )
        guard result == KERN_SUCCESS,
              let dictionary = properties?.takeRetainedValue() as? [String: Any]
        else {
            return [:]
        }
        return dictionary
    }

    private static func timeRemainingMinutes(
        source: BatterySnapshot.PowerSource
    ) -> Int? {
        guard source == .battery else { return nil }
        let seconds = IOPSGetTimeRemainingEstimate()
        guard seconds.isFinite, seconds > 0 else { return nil }
        return Int((seconds / 60).rounded())
    }

    private static func localizedCondition(_ condition: String?) -> String? {
        switch condition?.lowercased() {
        case "good", "normal":
            "正常"
        case "fair":
            "一般"
        case "poor", "check battery", "service recommended":
            "建议检修"
        case .some:
            condition
        case .none:
            nil
        }
    }

    private static func watts(fromMilliwatts value: Double?) -> Double? {
        guard let value, value >= 0 else { return nil }
        return value / 1_000
    }

    private static func dictionary(_ value: Any?) -> [String: Any] {
        value as? [String: Any] ?? [:]
    }

    private static func integer(_ value: Any?) -> Int? {
        if let value = value as? NSNumber { return value.intValue }
        if let value = value as? Int { return value }
        if let value = value as? String { return Int(value) }
        return nil
    }

    private static func double(_ value: Any?) -> Double? {
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? String { return Double(value) }
        return nil
    }

    private static func boolean(_ value: Any?) -> Bool? {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        return nil
    }

    private static func string(_ value: Any?) -> String? {
        value as? String
    }
}
