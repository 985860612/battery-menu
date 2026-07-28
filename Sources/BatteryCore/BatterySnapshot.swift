import Foundation

public struct BatterySnapshot: Sendable, Equatable, Codable {
    public enum PowerSource: String, Sendable, Codable {
        case adapter
        case battery
        case unknown
    }

    public enum ChargeState: String, Sendable, Codable {
        case charging
        case paused
        case discharging
        case full
        case unknown
    }

    public var percentage: Int
    public var powerSource: PowerSource
    public var chargeState: ChargeState
    public var temperatureCelsius: Double?
    public var healthPercentage: Int?
    public var healthCondition: String?
    public var cycleCount: Int?
    public var designCycleCount: Int?
    public var timeRemainingMinutes: Int?

    public var adapterName: String?
    public var adapterRatedWatts: Int?
    public var adapterVoltageVolts: Double?
    public var adapterCurrentAmps: Double?

    public var adapterInputWatts: Double?
    public var systemLoadWatts: Double?
    public var batteryWatts: Double?
    public var sampledAt: Date

    public init(
        percentage: Int = 0,
        powerSource: PowerSource = .unknown,
        chargeState: ChargeState = .unknown,
        temperatureCelsius: Double? = nil,
        healthPercentage: Int? = nil,
        healthCondition: String? = nil,
        cycleCount: Int? = nil,
        designCycleCount: Int? = nil,
        timeRemainingMinutes: Int? = nil,
        adapterName: String? = nil,
        adapterRatedWatts: Int? = nil,
        adapterVoltageVolts: Double? = nil,
        adapterCurrentAmps: Double? = nil,
        adapterInputWatts: Double? = nil,
        systemLoadWatts: Double? = nil,
        batteryWatts: Double? = nil,
        sampledAt: Date = Date()
    ) {
        self.percentage = percentage
        self.powerSource = powerSource
        self.chargeState = chargeState
        self.temperatureCelsius = temperatureCelsius
        self.healthPercentage = healthPercentage
        self.healthCondition = healthCondition
        self.cycleCount = cycleCount
        self.designCycleCount = designCycleCount
        self.timeRemainingMinutes = timeRemainingMinutes
        self.adapterName = adapterName
        self.adapterRatedWatts = adapterRatedWatts
        self.adapterVoltageVolts = adapterVoltageVolts
        self.adapterCurrentAmps = adapterCurrentAmps
        self.adapterInputWatts = adapterInputWatts
        self.systemLoadWatts = systemLoadWatts
        self.batteryWatts = batteryWatts
        self.sampledAt = sampledAt
    }
}
