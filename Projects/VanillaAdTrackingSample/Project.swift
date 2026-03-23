import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VanillaAdTrackingSample",
    organizationName: .revenueCatOrgName,
    packages: .vanillaAdTrackingPackages,
    settings: .appProject,
    targets: [
        .target(
            name: "VanillaAdTrackingSample",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.revenuecat.sample.VanillaAdTrackingSample",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511"
            ]),
            sources: ["../../Examples/VanillaAdTrackingSample/Sources/**"],
            dependencies: [
                .revenueCat,
                .googleMobileAds
            ],
            settings: .appTarget
        )
    ]
)
