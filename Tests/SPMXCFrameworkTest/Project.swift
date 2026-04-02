import ProjectDescription

let project = Project(
    name: "SPMXCFrameworkTest",
    targets: [
        .target(
            name: "SPMXCFrameworkTest",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.revenuecat.spmxcframeworktest",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": ["UIColorName": "", "UIImageName": ""]
            ]),
            sources: ["Sources/**/*.swift"],
            dependencies: [
                .xcframework(path: "../../RevenueCat.xcframework"),
                .xcframework(path: "../../RevenueCatUI.xcframework")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "SPMXCFrameworkTest",
            shared: true,
            buildAction: .buildAction(targets: ["SPMXCFrameworkTest"]),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)
