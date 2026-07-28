// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BatteryMenu",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "BatteryCore", targets: ["BatteryCore"]),
        .executable(name: "BatteryMenu", targets: ["BatteryMenu"]),
        .executable(name: "battery-dump", targets: ["BatteryDump"])
    ],
    targets: [
        .target(
            name: "BatteryCore",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "BatteryMenu",
            dependencies: ["BatteryCore"]
        ),
        .executableTarget(
            name: "BatteryDump",
            dependencies: ["BatteryCore"]
        )
    ]
)
