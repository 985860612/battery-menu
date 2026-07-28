import Foundation

public struct PowerSample: Sendable, Equatable, Codable, Identifiable {
    public var id: Date { timestamp }

    public let timestamp: Date
    public let adapterWatts: Double
    public let batteryWatts: Double
    public let systemWatts: Double

    public init(
        timestamp: Date,
        adapterWatts: Double,
        batteryWatts: Double,
        systemWatts: Double
    ) {
        self.timestamp = timestamp
        self.adapterWatts = adapterWatts
        self.batteryWatts = batteryWatts
        self.systemWatts = systemWatts
    }
}
