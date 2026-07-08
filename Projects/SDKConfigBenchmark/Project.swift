import ProjectDescription
import ProjectDescriptionHelpers

// Benchmark harness for comparing the legacy offerings flow against the remote config
// endpoint flow. Compiles the SDK sources directly (like BinarySizeTest does for its
// local-source mode) so the benchmark can drive internal manager-level APIs without
// exposing new public SDK API. `SDK_CONFIG_BENCHMARK` installs a simulated transport
// in `HTTPClient`; `ENABLE_REMOTE_CONFIG` turns on the remote config gate.
let benchmarkSwiftConditions: SettingsDictionary = [
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) SDK_CONFIG_BENCHMARK ENABLE_REMOTE_CONFIG"
]

let project = Project(
    name: "SDKConfigBenchmark",
    organizationName: .revenueCatOrgName,
    settings: .framework,
    targets: [
        .target(
            name: "SDKConfigBenchmarkCore",
            destinations: [.mac],
            product: .staticLibrary,
            bundleId: "com.revenuecat.SDKConfigBenchmarkCore",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .default,
            sources: [
                "../../Tests/Benchmarks/SDKConfigBenchmark/Sources/**/*.swift",
                .glob(
                    "../../Sources/**/*.swift",
                    excluding: [
                        "../../Sources/LocalReceiptParsing/ReceiptParser-only-files/**/*.swift"
                    ]
                )
            ],
            dependencies: [
                .storeKit
            ],
            settings: .settings(
                base: benchmarkSwiftConditions.appendingTuistSwiftConditions()
            )
        ),
        .target(
            name: "SDKConfigBenchmark",
            destinations: [.mac],
            product: .commandLineTool,
            bundleId: "com.revenuecat.SDKConfigBenchmark",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .default,
            sources: [
                "../../Tests/Benchmarks/SDKConfigBenchmark/Main/**/*.swift"
            ],
            dependencies: [
                .target(name: "SDKConfigBenchmarkCore")
            ],
            settings: .settings(
                base: benchmarkSwiftConditions.appendingTuistSwiftConditions()
            )
        ),
        .target(
            name: "SDKConfigBenchmarkTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.revenuecat.SDKConfigBenchmarkTests",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .default,
            sources: [
                "../../Tests/Benchmarks/SDKConfigBenchmark/Tests/**/*.swift"
            ],
            dependencies: [
                .target(name: "SDKConfigBenchmarkCore")
            ],
            settings: .settings(
                base: benchmarkSwiftConditions.appendingTuistSwiftConditions()
            )
        )
    ],
    schemes: [
        .scheme(
            name: "SDKConfigBenchmark",
            shared: true,
            buildAction: .buildAction(targets: ["SDKConfigBenchmark"]),
            runAction: .runAction(configuration: "Release")
        ),
        .scheme(
            name: "SDKConfigBenchmarkTests",
            shared: true,
            buildAction: .buildAction(targets: ["SDKConfigBenchmarkTests"]),
            testAction: .targets(["SDKConfigBenchmarkTests"])
        )
    ]
)
