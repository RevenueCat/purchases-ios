import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "BinarySizeTest",
    organizationName: .revenueCatOrgName,
    settings: .settings(
        base: [
            "SWIFT_COMPILATION_MODE": "wholemodule",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "CODE_SIGN_STYLE": "Manual",
            "DEVELOPMENT_TEAM": "8SXR2327BM"
        ],
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
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Manual",
                    "CODE_SIGN_IDENTITY": "Apple Distribution",
                    "DEVELOPMENT_TEAM": "8SXR2327BM"
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
