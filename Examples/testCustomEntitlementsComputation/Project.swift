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
    settings: .settings(base: [:].automaticCodeSigning(devTeam: .revenueCatTeamID)),
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
            ]
        )
    ],
)