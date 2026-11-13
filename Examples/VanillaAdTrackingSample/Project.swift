import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VanillaAdTrackingSample",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages + [
        .package(
            url: "https://github.com/ironsource-mobile/LevelPlay-Swift-Package",
            .upToNextMajor(from: "9.5.0")
        )
    ],
    settings: .appProject,
    targets: [
        .target(
            name: "VanillaAdTrackingSample",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.revenuecat.sample.VanillaAdTrackingSample",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .file(path: "Info.plist"),
            sources: ["Sources/**"],
            dependencies: [
                .revenueCat,
                .package(product: "UnityMediationSDK", type: .runtime)
            ],
            settings: .appTarget(including: [
                "DEVELOPMENT_TEAM": "",
                "OTHER_LDFLAGS": "$(inherited) -ObjC"
            ])
        )
    ]
)
