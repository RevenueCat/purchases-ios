import ProjectDescription

let project = Project(
    name: "RevenueCatUI",
    organizationName: "RevenueCat, Inc.",
    targets: [
        .target(
            name: "RevenueCatUI",
            destinations: .iOS,
            product: .staticLibrary,
            bundleId: "com.revenuecat.sampleapp",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": ""
                    ]
                ]
            ),
            sources: [
                "../../RevenueCatUI/**/*.swift"
            ],
            dependencies: [
                .project(target: "RevenueCat", path: "../RevenueCat")
            ]
        )
    ]
)
