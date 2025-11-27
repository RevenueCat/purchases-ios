import ProjectDescription
import ProjectDescriptionHelpers

let allDestinations: Destinations = [
    .iPhone,
    .iPad,
    .macWithiPadDesign,
    .appleVisionWithiPadDesign
]

let project = Project(
    name: "testCustomEntitlementsComputation",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .appProject,
    targets: [
        .target(
            name: "testCustomEntitlementsComputation",
            destinations: allDestinations,
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
                .revenueCat,
                .revenueCatUI,
            ].compactMap { $0 },
            settings: .appTarget(including: [
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION"
                ]
            )
        )
    ],
)
