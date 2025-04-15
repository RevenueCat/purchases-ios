import ProjectDescription

let project = Project(
    name: "rc-maestro",
    targets: [
        .target(
            name: "rc-maestro",
            destinations: .iOS,
            product: .app,
            bundleId: "com.revenuecat.maestro.ios",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["rc-maestro/Sources/**"],
            resources: ["rc-maestro/Resources/**"],
            dependencies: [
                .external(name: "RevenueCat"), 
                .external(name: "RevenueCatUI"), 
            ]
        ),
        .target(
            name: "rc-maestroTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.revenuecat.maestro.ios.rc-maestroTests",
            infoPlist: .default,
            sources: ["rc-maestro/Tests/**"],
            resources: [],
            dependencies: [.target(name: "rc-maestro")]
        ),
        .target(
            name: "rc_maestroUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.revenuecat.maestro.ios.rc-maestroUITests",
            infoPlist: .default,
            sources: ["rc_maestroUITests/**"],
            resources: [],
            dependencies: [
                .target(name: "rc-maestro"),
                .sdk(name: "StoreKitTest", type: .framework, status: .required)
            ]
        ),
    ]
)
