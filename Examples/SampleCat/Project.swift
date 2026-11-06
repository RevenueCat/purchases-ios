import ProjectDescription
import ProjectDescriptionHelpers

// CI smoke build against the local SDK. Customers get `SampleCat.xcodeproj` from the dashboard download,
// so this project has a different name and does not overwrite it.
// AdMob is only pulled in when test/dev dependencies are included, so CI can skip the GoogleMobileAds
// download with TUIST_INCLUDE_TEST_DEPENDENCIES=false.
let adMobDependencies: [TargetDependency] = Environment.includeTestDependencies
    ? [.revenueCatAdMob, .googleMobileAds]
    : []
let adMobPackages: [ProjectDescription.Package] = Environment.includeTestDependencies
    ? .adMobPackage
    : []

let project = Project(
    name: "SampleCatTuist",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages + adMobPackages,
    settings: .appProject,
    targets: [
        .target(
            name: "SampleCat",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.revenuecat.app",
            deploymentTargets: .iOS("18.2"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    // Google's sample app id. Replace it with your own AdMob app id.
                    "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511",
                ]
            ),
            sources: ["SampleCat/**/*.swift"],
            resources: ["SampleCat/Utils/Assets.xcassets"],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
            ] + adMobDependencies,
            settings: .appTarget(including: [
                "SWIFT_VERSION": "6.0",
                "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            ])
        )
    ]
)
