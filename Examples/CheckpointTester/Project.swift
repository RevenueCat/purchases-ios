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

let project = Project(
    name: "CheckpointTester",
    organizationName: .revenueCatOrgName,
    packages: .projectPackages,
    settings: .appProject,
    targets: [
        .target(
            name: "CheckpointTester",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.revenuecat.PaywallsTester",
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
                ]
            ),
            sources: ["CheckpointTester/Sources/**/*.swift"],
            resources: ["CheckpointTester/Resources/**/*.json"],
            dependencies: [
                .revenueCat,
                .revenueCatUI,
            ],
            settings: .appTarget(including: [
                "DEVELOPMENT_TEAM": "",
            ])
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
                executable: "CheckpointTester"
            )
        ),
    ]
)
