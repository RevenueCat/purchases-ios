//
//  checkpoint-test-harness.swift
//  Maestro
//
//  Created by Rick van der Linden on 15/10/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import SwiftUI
import UIKit
@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI

@MainActor
struct CheckpointBackendE2ETestView: View {

    let checkpointIdentifier: String

    @State private var callbackStatus = "Callback: not invoked"
    @State private var callbackCount = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Published checkpoint")
                .font(.title)

            Text("Identifier: \(self.checkpointIdentifier)")

            Button("Hit checkpoint") {
                Purchases.shared.checkpoint(
                    self.checkpointIdentifier,
                    customVariables: ["source": "maestro"]
                ) { result in
                    self.callbackCount += 1
                    self.callbackStatus = checkpointCallbackStatus(result, callCount: self.callbackCount)
                }
            }
            .buttonStyle(.borderedProminent)

            Text(self.callbackStatus)
        }
        .multilineTextAlignment(.center)
        .padding()
    }

}

@MainActor
struct CheckpointE2ETestView: View {

    private let testCase: CheckpointE2ETestCase
    private let usesCustomErrorPresenter: Bool

    @State private var callbackStatus = "Callback: not invoked"
    @State private var callbackCount = 0
    private let customErrorPresenter: CheckpointE2ECustomErrorPresenter

    init(
        testCase: CheckpointE2ETestCase,
        usesCustomErrorPresenter: Bool = false,
        preferredUILocale: String = "en"
    ) {
        let customErrorPresenter = CheckpointE2ECustomErrorPresenter()
        self.testCase = testCase
        self.usesCustomErrorPresenter = usesCustomErrorPresenter
        self.customErrorPresenter = customErrorPresenter
        let workflowPresenter: WorkflowPresenter
        if testCase == .purchaseFailure {
            workflowPresenter = WorkflowPresenter(
                performPurchase: { _ in
                    return (
                        userCancelled: false,
                        error: ErrorUtils.testStoreSimulatedPurchaseError()
                    )
                },
                performRestore: { (success: false, error: nil) }
            )
        } else {
            workflowPresenter = WorkflowPresenter()
        }
        let customerInfoSynchronizer: CheckpointsManager.CustomerInfoSynchronizer
        if testCase == .resultSyncFailure {
            customerInfoSynchronizer = { throw CheckpointE2ETestError.resultSyncFailed }
        } else {
            customerInfoSynchronizer = { throw CancellationError() }
        }
        _ = Purchases.shared.getOrCreateCheckpointsManager {
            CheckpointsManager(
                resolveCheckpoint: { identifier, _ in
                    try await testCase.resolve(identifier: identifier)
                },
                checkpointPresenter: CheckpointPresenter(
                    workflowPresenter: workflowPresenter,
                    customerInfoSynchronizer: customerInfoSynchronizer
                ),
                preferredUILocaleProvider: { preferredUILocale }
            )
        }
        Purchases.shared.errorPresenter = usesCustomErrorPresenter ? customErrorPresenter : nil
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(self.testCase.title)
                .font(.title)

            Button("Hit checkpoint") {
                Purchases.shared.checkpoint(
                    self.testCase.checkpointIdentifier,
                    customVariables: ["source": "maestro"]
                ) { result in
                    self.callbackCount += 1
                    self.callbackStatus = checkpointCallbackStatus(result, callCount: self.callbackCount)
                }
            }
            .buttonStyle(.borderedProminent)

            Text(self.callbackStatus)

            if self.usesCustomErrorPresenter {
                Text("Using custom error presenter")
            }
        }
        .multilineTextAlignment(.center)
        .padding()
    }

}

private func checkpointCallbackStatus(_ result: FlowResult?, callCount: Int) -> String {
    let entitlementDescription: String
    if let result {
        let entitlements = result.obtainedEntitlements
            .map(\.entitlementInfo.identifier)
            .sorted()
            .joined(separator: ", ")
        entitlementDescription = entitlements.isEmpty ? "none" : entitlements
    } else {
        entitlementDescription = "nil"
    }
    return "Callback: \(entitlementDescription) (call #\(callCount))"
}

@MainActor
private final class CheckpointE2ECustomErrorPresenter: ErrorPresenter {

    func present(params: ErrorPresentationParams, completion: ErrorPresentationCompletion) {
        let kind = Self.name(for: params.kind)
        let message = [
            "Kind: \(kind)",
            "Checkpoint: \(params.checkpointIdentifier)",
            "Custom variable keys: \(params.customVariables.keys.sorted().joined(separator: ", "))",
            "Error: \((params.error as NSError).localizedDescription)"
        ].joined(separator: "\n")
        let alert = UIAlertController(
            title: "Custom error presenter: \(kind)",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Dismiss custom error", style: .default) { _ in
            completion.complete()
        })

        guard let host = UIApplication.shared.currentPresentationViewController else {
            completion.complete()
            return
        }
        host.present(alert, animated: true)
    }

    private static func name(for kind: CheckpointFailureKind) -> String {
        switch kind {
        case .flowCouldNotBeShown:
            return "flowCouldNotBeShown"
        case .flowActionFailed:
            return "flowActionFailed"
        case .flowResultSyncFailed:
            return "flowResultSyncFailed"
        default:
            return "unknown"
        }
    }

}

@MainActor
enum CheckpointE2ETestCase: Equatable {

    case invalidIdentifier
    case resolutionFailure
    case configurationUnavailable
    case initialScreenFailure
    case secondScreenFailure
    case purchaseFailure
    case resultSyncFailure
    case successfulWorkflow
    case noMatch

    var title: String {
        switch self {
        case .invalidIdentifier:
            return "Checkpoint invalid identifier"
        case .resolutionFailure:
            return "Checkpoint resolution failure"
        case .configurationUnavailable:
            return "Checkpoint configuration unavailable"
        case .initialScreenFailure:
            return "Checkpoint initial screen failure"
        case .secondScreenFailure:
            return "Checkpoint second screen failure"
        case .purchaseFailure:
            return "Checkpoint purchase failure"
        case .resultSyncFailure:
            return "Checkpoint result sync failure"
        case .successfulWorkflow:
            return "Checkpoint successful Workflow"
        case .noMatch:
            return "Checkpoint no match"
        }
    }

    var checkpointIdentifier: String {
        switch self {
        case .invalidIdentifier:
            return "bad id!"
        case .resolutionFailure,
             .configurationUnavailable,
             .initialScreenFailure,
             .secondScreenFailure,
             .purchaseFailure,
             .resultSyncFailure,
             .successfulWorkflow,
             .noMatch:
            return "maestro_checkpoint"
        }
    }

    func resolve(identifier _: String) async throws -> CheckpointResolution {
        switch self {
        case .invalidIdentifier:
            return .noAction(.noMatch)
        case .resolutionFailure:
            throw CheckpointE2ETestError.resolutionFailed
        case .configurationUnavailable:
            return .noAction(.configurationUnavailable)
        case .initialScreenFailure:
            return Self.initialScreenFailureResolution()
        case .secondScreenFailure:
            return Self.secondScreenFailureResolution()
        case .purchaseFailure:
            return Self.purchaseFailureResolution()
        case .resultSyncFailure:
            return .matchedOffering(TestData.offeringWithNoIntroOffer)
        case .successfulWorkflow:
            return Self.successfulWorkflowResolution()
        case .noMatch:
            return .noAction(.noMatch)
        }
    }

    private static func successfulWorkflowResolution() -> CheckpointResolution {
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

    private static func initialScreenFailureResolution() -> CheckpointResolution {
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

    private static func secondScreenFailureResolution() -> CheckpointResolution {
        return .matchedWorkflow(
            ResolvedCheckpointWorkflow(
                workflow: Self.secondScreenFailureWorkflow,
                uiConfig: .empty,
                offerings: .preview(offerings: [])
            )
        )
    }

    private static func purchaseFailureResolution() -> CheckpointResolution {
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

private enum CheckpointE2ETestError: LocalizedError {

    case resolutionFailed
    case resultSyncFailed

    var errorDescription: String? {
        switch self {
        case .resolutionFailed:
            return "Maestro checkpoint resolution failed."
        case .resultSyncFailed:
            return "Maestro customer info synchronization failed."
        }
    }

}
