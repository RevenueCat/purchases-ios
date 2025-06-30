import ProjectDescription
import ProjectDescriptionHelpers
import Foundation

var additionalFiles: [FileElement] = [
    .glob(pattern: "rc-maestro/Resources/**/Local.xcconfig.sample")
]
var shouldAddLocalConfig: Bool = false
if FileManager.default.fileExists(atPath: "rc-maestro/Resources/**/Local.xcconfig") {
    shouldAddLocalConfig = true
     additionalFiles.append(.glob(pattern: "rc-maestro/Resources/**/Local.xcconfig"))
}

let project = Project(
    name: "Maestro",
    organizationName: .revenueCatOrgName,
    settings: .settings(
        base: [:].automaticCodeSigning(devTeam: .revenueCatTeamID),
        defaultSettings: .essential
    ),
    targets: [
        .target(
            name: "Maestro-Debug",
            destinations: .iOS,
            product: .app,
            bundleId: "com.revenuecat.maestro.ios",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "REVENUECAT_API_KEY": "$(REVENUECAT_API_KEY)"
                ]
            ),
            sources: ["rc-maestro/Sources/**/*.swift"],
            resources: [
                "rc-maestro/Resources/**/*.xcassets",
            ],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .storeKit
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "Maestro-Debug",
            shared: true,
            hidden: false,
            buildAction: .buildAction(targets: ["Maestro-Debug"], findImplicitDependencies: true),
            runAction: .runAction(
                configuration: "Debug",
                executable: "Maestro-Debug",
                options: .options(
                    storeKitConfigurationPath: "rc-maestro/Resources/StoreKit/StoreKitConfiguration.storekit"
                )
            )
        )
    ],
    additionalFiles: additionalFiles
)