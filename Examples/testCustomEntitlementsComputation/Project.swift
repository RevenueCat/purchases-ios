import ProjectDescription

let project = Project(
    name: "testCustomEntitlementsComputation",
    organizationName: "RevenueCat, Inc.",
    targets: [
        .target(
            name: "testCustomEntitlementsComputation",
            destinations: .iOS,
            product: .app,
            bundleId: "com.revenuecat.sampleapp",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ]
                ]
            ),
            sources: [
                "testCustomEntitlementsComputation/Sources/**/*.swift",
                "testCustomEntitlementsComputation/Constants.swift"
                ],
            resources: [
                "testCustomEntitlementsComputation/Resources/**/*.xcassets",
            ],
            dependencies: [
                .external(name: "RevenueCat"),
                .external(name: "RevenueCatUI"),
            ]
        )
    ]
)