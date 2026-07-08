import ProjectDescription
import ProjectDescriptionHelpers

// Benchmark harness for comparing the legacy offerings flow against the remote config
// endpoint flow. Compiles the SDK sources directly (like BinarySizeTest does for its
// local-source mode) so the benchmark can drive internal manager-level APIs without
// exposing new public SDK API. `SDK_CONFIG_BENCHMARK` installs a simulated transport
// in `HTTPClient`; `ENABLE_REMOTE_CONFIG` turns on the remote config gate.
//
// TUIST_SWIFT_CONDITIONS is folded in by hand instead of via
// `appendingTuistSwiftConditions()`, because that helper replaces the whole
// SWIFT_ACTIVE_COMPILATION_CONDITIONS value and would silently drop the benchmark flags.
let benchmarkSwiftConditions: SettingsDictionary = [
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": SettingValue(stringLiteral: (
        ["$(inherited)", "SDK_CONFIG_BENCHMARK", "ENABLE_REMOTE_CONFIG"] + Environment.extraSwiftConditions
    ).joined(separator: " "))
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
                base: benchmarkSwiftConditions
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
                // The SDK's disk caches derive their directory from Bundle.main.bundleIdentifier,
                // which a bare command-line binary does not have. Embedding the Info.plist into
                // the binary gives it one, so etags/offerings/remote-config persistence works.
                base: benchmarkSwiftConditions
                    .merging(["CREATE_INFOPLIST_SECTION_IN_BINARY": "YES"])
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
                base: benchmarkSwiftConditions
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
