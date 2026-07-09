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
        )
    ],
    schemes: [
        .scheme(
            name: "SDKConfigBenchmarkApp",
            shared: true,
            buildAction: .buildAction(targets: ["SDKConfigBenchmarkApp"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "SDKConfigBenchmarkApp"
            )
        )
    ]
)
