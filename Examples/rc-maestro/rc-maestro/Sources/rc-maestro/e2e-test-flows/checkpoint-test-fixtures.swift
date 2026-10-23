//
//  checkpoint-test-fixtures.swift
//  Maestro
//
//  Created by Rick van der Linden on 16/10/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI

@MainActor
enum CheckpointE2EFixtures {

    static func successfulWorkflowResolution() -> CheckpointResolution {
        return .matchedWorkflow(
            ResolvedCheckpointWorkflow(
                workflow: PublishedWorkflow(
                    id: "checkpoint-successful-workflow",
                    displayName: "Checkpoint successful Workflow",
                    initialStepId: "success-step",
                    singleStepFallbackId: nil,
                    steps: [
                        "success-step": WorkflowStep(
                            id: "success-step",
                            type: "screen",
                            screenId: "first-screen"
                        )
                    ],
                    screens: ["first-screen": Self.firstScreen]
                ),
                uiConfig: .empty,
                offerings: .preview(offerings: [])
            )
        )
    }

    static func initialScreenFailureResolution() -> CheckpointResolution {
        return .matchedWorkflow(
            ResolvedCheckpointWorkflow(
                workflow: PublishedWorkflow(
                    id: "checkpoint-initial-screen-failure",
                    displayName: "Checkpoint initial screen failure",
                    initialStepId: "initial-step",
                    singleStepFallbackId: nil,
                    steps: [
                        "initial-step": WorkflowStep(
                            id: "initial-step",
                            type: "screen",
                            screenId: "__maestro_missing_initial_screen__"
                        )
                    ],
                    screens: [:]
                ),
                uiConfig: .empty,
                offerings: .preview(offerings: [])
            )
        )
    }

    static func secondScreenFailureResolution() -> CheckpointResolution {
        return .matchedWorkflow(
            ResolvedCheckpointWorkflow(
                workflow: Self.secondScreenFailureWorkflow,
                uiConfig: .empty,
                offerings: .preview(offerings: [])
            )
        )
    }

    static func purchaseFailureResolution() -> CheckpointResolution {
        let offering = Offering(
            identifier: "offering",
            serverDescription: "Checkpoint E2E purchase offering",
            availablePackages: [TestData.monthlyPackage],
            webCheckoutUrl: nil
        )
        return .matchedWorkflow(
            ResolvedCheckpointWorkflow(
                workflow: PublishedWorkflow(
                    id: "checkpoint-purchase-failure",
                    displayName: "Checkpoint purchase failure",
                    initialStepId: "purchase-step",
                    singleStepFallbackId: nil,
                    steps: [
                        "purchase-step": WorkflowStep(
                            id: "purchase-step",
                            type: "screen",
                            screenId: "purchase-screen"
                        )
                    ],
                    screens: [
                        "purchase-screen": Self.purchaseScreen(
                            packageIdentifier: TestData.monthlyPackage.identifier,
                            offeringIdentifier: offering.identifier
                        )
                    ]
                ),
                uiConfig: .empty,
                offerings: .preview(offerings: [offering])
            )
        )
    }

    private static var secondScreenFailureWorkflow: PublishedWorkflow {
        return PublishedWorkflow(
            id: "checkpoint-second-screen-failure",
            displayName: "Checkpoint second screen failure",
            initialStepId: "first-step",
            singleStepFallbackId: nil,
            steps: [
                "first-step": WorkflowStep(
                    id: "first-step",
                    type: "screen",
                    screenId: "first-screen",
                    triggers: [
                        WorkflowTrigger(
                            name: "Continue",
                            type: .onPress,
                            actionId: "show-second-step",
                            componentId: "continue-button"
                        )
                    ],
                    triggerActions: ["show-second-step": .step(stepId: "second-step")]
                ),
                "second-step": WorkflowStep(
                    id: "second-step",
                    type: "screen",
                    screenId: "__maestro_missing_screen__"
                )
            ],
            screens: ["first-screen": Self.firstScreen]
        )
    }

    private static var firstScreen: WorkflowScreen {
        let foregroundColor = PaywallComponent.ColorScheme(light: .hex("#111111"))
        let buttonText = PaywallComponent.TextComponent(
            text: "continue",
            fontWeight: .bold,
            color: foregroundColor
        )
        let button = PaywallComponent.ButtonComponent(
            id: "continue-button",
            action: .workflowTrigger,
            stack: .init(
                components: [.text(buttonText)],
                backgroundColor: .init(light: .hex("#F2C94C")),
                padding: .default
            )
        )
        let title = PaywallComponent.TextComponent(
            text: "title",
            fontWeight: .bold,
            color: foregroundColor,
            fontSize: 28
        )
        let root = PaywallComponent.StackComponent(
            components: [.text(title), .button(button)],
            dimension: .vertical(.center, .center),
            spacing: 24,
            padding: .default
        )

        return WorkflowScreen(
            name: "First screen",
            templateName: "checkpoint-e2e",
            assetBaseURL: URL(fileURLWithPath: "/"),
            componentsConfig: .init(
                base: .init(
                    stack: root,
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#FFFFFF")))
                )
            ),
            componentsLocalizations: [
                "en": [
                    "title": .string("First screen loaded"),
                    "continue": .string("Continue")
                ]
            ],
            defaultLocale: "en",
            offeringIdentifier: nil
        )
    }

    private static func purchaseScreen(
        packageIdentifier: String,
        offeringIdentifier: String
    ) -> WorkflowScreen {
        let foregroundColor = PaywallComponent.ColorScheme(light: .hex("#111111"))
        let package = PaywallComponent.PackageComponent(
            packageID: packageIdentifier,
            isSelectedByDefault: true,
            applePromoOfferProductCode: nil,
            stack: .init(
                components: [
                    .text(.init(text: "package", fontWeight: .bold, color: foregroundColor))
                ],
                backgroundColor: .init(light: .hex("#F2F2F2")),
                padding: .default
            )
        )
        let purchaseButton = PaywallComponent.PurchaseButtonComponent(
            stack: .init(
                components: [
                    .text(.init(
                        text: "purchase",
                        fontWeight: .bold,
                        color: .init(light: .hex("#FFFFFF"))
                    ))
                ],
                backgroundColor: .init(light: .hex("#5B2EFF")),
                padding: .default
            ),
            action: .inAppCheckout,
            method: .inAppCheckout,
            name: nil
        )
        let root = PaywallComponent.StackComponent(
            components: [
                .text(.init(text: "title", fontWeight: .bold, color: foregroundColor, fontSize: 28)),
                .package(package),
                .purchaseButton(purchaseButton)
            ],
            dimension: .vertical(.center, .center),
            spacing: 24,
            padding: .default
        )

        return WorkflowScreen(
            name: "Purchase screen",
            templateName: "checkpoint-e2e",
            assetBaseURL: URL(fileURLWithPath: "/"),
            componentsConfig: .init(
                base: .init(
                    stack: root,
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#FFFFFF")))
                )
            ),
            componentsLocalizations: [
                "en": [
                    "title": .string("Test Store purchase Flow"),
                    "package": .string("Monthly test package"),
                    "purchase": .string("Test purchase")
                ]
            ],
            defaultLocale: "en",
            offeringIdentifier: offeringIdentifier
        )
    }

}
