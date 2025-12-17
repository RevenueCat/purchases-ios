import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "BinarySizeTest",
    organizationName: .revenueCatOrgName,
    settings: .settings(
        base: .projectBase,
        configurations: [
            .debug(
                name: "Debug",
                settings: [
                    "SWIFT_COMPILATION_MODE": "incremental"
                ]
            ),
            .release(
                name: "Release",
                settings: [
                    "SWIFT_COMPILATION_MODE": "wholemodule"
                ]
            )
        ],
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
            settings: .appTarget
        )
    ],
    schemes: [
        .scheme(
            name: "BinarySizeTest",
            shared: true,
            buildAction: .buildAction(targets: ["BinarySizeTest"]),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)
