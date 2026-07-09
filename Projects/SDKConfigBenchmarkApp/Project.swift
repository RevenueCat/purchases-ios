import ProjectDescription
import ProjectDescriptionHelpers

// App-host tier of the SDK config benchmark: a minimal iOS app that links the stock
// RevenueCat/RevenueCatUI products (unlike Projects/SDKConfigBenchmark, which compiles the
// SDK sources directly) and measures a real `Purchases.configure` launch end to end.
// Local/CI only; driven by Tests/TestingApps/SDKConfigBenchmarkApp/run-app-launch.sh.
//
// The legacy-vs-config variant switch is NOT set here: the SPM-built RevenueCat reads
// `SWIFT_ACTIVE_COMPILATION_CONDITIONS` from Local.xcconfig (see Package.swift), which the
// runner script rewrites per variant.

// Injected into the scheme's run environment so the app can be launched straight from Xcode:
//   TUIST_BENCH_API_KEY=<key> tuist generate SDKConfigBenchmarkApp
// Without it, a direct run reports "BENCH_API_KEY missing" by design (keys never live in
// source or in committed scheme files).
let runEnvironment: [String: EnvironmentVariable] = {
    var environment: [String: EnvironmentVariable] = [:]
    if let apiKey = Environment.benchApiKey {
        environment["BENCH_API_KEY"] = .environmentVariable(value: apiKey, isEnabled: true)
        environment["BENCH_APP_USER_ID"] = .environmentVariable(value: "bench-xcode-run", isEnabled: true)
    }
    return environment
}()

let project = Project(
    name: "SDKConfigBenchmarkApp",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .appProject,
    targets: [
        .target(
            name: "SDKConfigBenchmarkApp",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.revenuecat.SDKConfigBenchmarkApp",
            deploymentTargets: .iOS("16.0"),
            infoPlist: "../../Tests/TestingApps/SDKConfigBenchmarkApp/App/Info.plist",
            sources: [
                "../../Tests/TestingApps/SDKConfigBenchmarkApp/App/**/*.swift"
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI
            ],
            settings: .appTarget(including: ([:] as SettingsDictionary).appendingTuistSwiftConditions())
        ),
        .target(
            name: "SDKConfigBenchmarkAppUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "com.revenuecat.SDKConfigBenchmarkAppUITests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "../../Tests/TestingApps/SDKConfigBenchmarkApp/UITests/**/*.swift",
                // Shared with the app target: the runner decodes the same LaunchSample
                // the app encodes.
                "../../Tests/TestingApps/SDKConfigBenchmarkApp/App/LaunchMeasurement.swift"
            ],
            dependencies: [
                .target(name: "SDKConfigBenchmarkApp")
            ],
            settings: .appTarget
        )
    ],
    schemes: [
        .scheme(
            name: "SDKConfigBenchmarkApp",
            shared: true,
            buildAction: .buildAction(targets: ["SDKConfigBenchmarkApp"]),
            testAction: .targets(["SDKConfigBenchmarkAppUITests"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "SDKConfigBenchmarkApp",
                arguments: .arguments(environmentVariables: runEnvironment)
            )
        )
    ]
)
