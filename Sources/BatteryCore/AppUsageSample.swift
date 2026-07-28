import Foundation

public struct AppUsageSample: Sendable, Equatable, Codable, Identifiable {
    public var id: String { appPath }

    public let name: String
    public let appPath: String
    public let energyImpact: Double

    public init(name: String, appPath: String, energyImpact: Double) {
        self.name = name
        self.appPath = appPath
        self.energyImpact = energyImpact
    }
}

public enum AppUsageReader {
    public static func readTopApps(limit: Int = 3) -> [AppUsageSample] {
        guard let topOutput = run(
            executable: "/usr/bin/top",
            arguments: [
                "-l", "2",
                "-n", "200",
                "-o", "power",
                "-stats", "pid,power"
            ]
        ),
        let processOutput = run(
            executable: "/bin/ps",
            arguments: ["-axo", "pid=,comm="]
        ) else {
            return []
        }

        let impacts = parseEnergyImpact(topOutput)
        let paths = parseProcessPaths(processOutput)
        var totals: [String: Double] = [:]

        for (pid, impact) in impacts {
            guard impact > 0,
                  let path = paths[pid],
                  let appPath = rootApplicationPath(in: path),
                  !appPath.hasSuffix("/Battery Menu.app")
            else {
                continue
            }
            totals[appPath, default: 0] += impact
        }

        return totals
            .map { path, impact in
                AppUsageSample(
                    name: URL(fileURLWithPath: path)
                        .deletingPathExtension()
                        .lastPathComponent,
                    appPath: path,
                    energyImpact: min(impact, 9_999)
                )
            }
            .sorted { $0.energyImpact > $1.energyImpact }
            .prefix(max(0, limit))
            .map { $0 }
    }

    private static func run(executable: String, arguments: [String]) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0,
                  let output = String(data: data, encoding: .utf8)
            else {
                return nil
            }
            return output
        } catch {
            return nil
        }
    }

    private static func parseEnergyImpact(_ output: String) -> [Int: Double] {
        var result: [Int: Double] = [:]
        var readingProcesses = false

        for line in output.split(separator: "\n") {
            let fields = line.split(whereSeparator: \.isWhitespace)
            if fields.count >= 2, fields[0] == "PID", fields[1] == "POWER" {
                // `top -l 2` prints two samples. Reset here so only the second,
                // fully sampled result remains.
                result = [:]
                readingProcesses = true
                continue
            }
            guard readingProcesses,
                  fields.count >= 2,
                  let pid = Int(fields[0]),
                  let impact = Double(fields[1])
            else {
                continue
            }
            result[pid] = impact
        }
        return result
    }

    private static func parseProcessPaths(_ output: String) -> [Int: String] {
        var result: [Int: String] = [:]
        for line in output.split(separator: "\n") {
            let fields = line.split(
                maxSplits: 1,
                whereSeparator: \.isWhitespace
            )
            guard fields.count == 2, let pid = Int(fields[0]) else { continue }
            result[pid] = String(fields[1])
        }
        return result
    }

    private static func rootApplicationPath(in executablePath: String) -> String? {
        guard executablePath.hasPrefix("/Applications/")
                || executablePath.hasPrefix("/System/Applications/"),
              let range = executablePath.range(of: ".app")
        else {
            return nil
        }
        return String(executablePath[..<range.upperBound])
    }
}
