//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Project.swift
//
//  Created by Rick van der Linden.
//

import ProjectDescription
import ProjectDescriptionHelpers

let storeKitConfigurationPath: Path =
    "../../Tests/TestingApps/PaywallsTester/PaywallsTester/Products.storekit"

let project = Project(
    name: "CheckpointTester",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages + .adMobPackage,
    settings: .appProject,
    targets: [
        .target(
            name: "CheckpointTester",
            destinations: [.iPhone, .iPad],
            product: .app,
            // Reuse PaywallsTester's existing products, workflows, and StoreKit configuration for this test app.
            bundleId: Environment.paywallsTesterBundleId,
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "REVENUECAT_API_KEY": .string(
                        Environment.rcApiKey ?? "$(REVENUECAT_API_KEY)"
                    ),
                    // Google's public test AdMob App ID, used by all of Google's own sample apps.
                    "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511",
                ]
            ),
            sources: ["CheckpointTester/Sources/**/*.swift"],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
                .revenueCatAdMob,
                .googleMobileAds,
            ],
            settings: .appTarget(
                including: ([
                    "DEVELOPMENT_TEAM": "",
                ] as SettingsDictionary).appendingTuistSwiftConditions()
            )
        ),
    ],
    schemes: [
        .scheme(
            name: "CheckpointTester",
            shared: true,
            buildAction: .buildAction(
                targets: ["CheckpointTester"],
                findImplicitDependencies: true
            ),
            runAction: .runAction(
                configuration: "Debug",
                executable: "CheckpointTester",
                options: .options(
                    storeKitConfigurationPath: storeKitConfigurationPath
                )
            )
        ),
    ]
)
