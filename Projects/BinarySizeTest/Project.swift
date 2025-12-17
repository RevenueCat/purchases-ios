import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "BinarySizeTest",
    organizationName: .revenueCatOrgName,
    settings: .settings(
        defaultSettings: .recommended
    ),
    targets: [
        .target(
            name: "BinarySizeTest",
            destinations: .iOS,
            product: .app,
            bundleId: "com.revenuecat.BinarySizeTestLocalSource",
            deploymentTargets: .iOS("13.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ]
                ]
            ),
            sources: [
                "BinarySizeTest/Sources/**/*.swift"
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Manual",
                    "DEVELOPMENT_TEAM": "8SXR2327BM",
                    "CODE_SIGN_IDENTITY": "Apple Distribution: RevenueCat, Inc. (8SXR2327BM)",
                    "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.revenuecat.BinarySizeTestLocalSource"
                ],
                defaultSettings: .essential
            )
        )
    ],
    schemes: [
        .scheme(
            name: "BinarySizeTest",
            shared: true,
            buildAction: .buildAction(targets: ["BinarySizeTest"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release")
        )
    ]
)
