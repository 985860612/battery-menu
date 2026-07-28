import BatteryCore
import Foundation

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
encoder.dateEncodingStrategy = .iso8601

if CommandLine.arguments.contains("--apps") {
    do {
        let data = try encoder.encode(AppUsageReader.readTopApps())
        print(String(decoding: data, as: UTF8.self))
        exit(0)
    } catch {
        FileHandle.standardError.write(Data("读取失败：\(error)\n".utf8))
        exit(1)
    }
}

let health = BatteryReader.readSystemHealth()
let snapshot = BatteryReader.readSnapshot(health: health)

do {
    let data = try encoder.encode(snapshot)
    print(String(decoding: data, as: UTF8.self))
} catch {
    FileHandle.standardError.write(Data("读取失败：\(error)\n".utf8))
    exit(1)
}
