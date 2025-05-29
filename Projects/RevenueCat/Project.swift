import ProjectDescription

let project = Project(
    name: "RevenueCat",
    organizationName: "RevenueCat, Inc.",
    targets: [
        .target(
            name: "RevenueCat",
            destinations: .iOS,
            product: .staticLibrary,
            bundleId: "com.revenuecat.sampleapp",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": ""
                    ]
                ]
            ),
            sources: [
                .glob(
                    "../../Sources/**/*.swift",
                    excluding: [
                        "../../Sources/LocalReceiptParsing/ReceiptParser-only-files/**/*.swift"
                    ]
                )

            ]
        )
    ]
)
