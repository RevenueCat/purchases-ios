import ProjectDescription
import ProjectDescriptionHelpers

// CI smoke build against the local SDK. Customers get `SampleCat.xcodeproj` from the dashboard download,
// so this project has a different name and does not overwrite it.
let project = Project(
    name: "SampleCatTuist",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
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
                    ]
                ]
            ),
            sources: ["SampleCat/**/*.swift"],
            resources: ["SampleCat/Utils/Assets.xcassets"],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
            ],
            settings: .appTarget(including: [
                "SWIFT_VERSION": "6.0",
                "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            ])
        )
    ]
)
