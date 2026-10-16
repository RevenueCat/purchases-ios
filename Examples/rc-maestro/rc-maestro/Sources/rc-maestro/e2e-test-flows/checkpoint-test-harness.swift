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
    private let usesCustomErrorPresenter: Bool

    @State private var callbackStatus = "Callback: not invoked"
    @State private var callbackCount = 0
    private let customErrorPresenter: CheckpointE2ECustomErrorPresenter

    init(checkpointIdentifier: String, usesCustomErrorPresenter: Bool = false) {
        let customErrorPresenter = CheckpointE2ECustomErrorPresenter()
        self.checkpointIdentifier = checkpointIdentifier
        self.usesCustomErrorPresenter = usesCustomErrorPresenter
        self.customErrorPresenter = customErrorPresenter
        Purchases.shared.errorPresenter = usesCustomErrorPresenter ? customErrorPresenter : nil
    }

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

            if self.usesCustomErrorPresenter {
                Text("Using custom error presenter")
            }
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
        if let purchaseError = testCase.injectedPurchaseError {
            workflowPresenter = WorkflowPresenter(
                performPurchase: { _ in
                    return (
                        userCancelled: false,
                        error: purchaseError
                    )
                },
                performRestore: { (success: false, error: nil) }
            )
        } else {
            workflowPresenter = WorkflowPresenter()
        }
        let customerInfoSynchronizer: CheckpointsManager.CustomerInfoSynchronizer
        if let synchronizationError = testCase.injectedCustomerInfoSynchronizationError {
            customerInfoSynchronizer = { throw synchronizationError }
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

    var injectedPurchaseError: (any Error)? {
        switch self {
        case .purchaseFailure:
            return ErrorUtils.testStoreSimulatedPurchaseError()
        default:
            return nil
        }
    }

    var injectedCustomerInfoSynchronizationError: (any Error)? {
        switch self {
        case .resultSyncFailure:
            return CheckpointE2ETestError.resultSyncFailed
        default:
            return nil
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
            return CheckpointE2EFixtures.initialScreenFailureResolution()
        case .secondScreenFailure:
            return CheckpointE2EFixtures.secondScreenFailureResolution()
        case .purchaseFailure:
            return CheckpointE2EFixtures.purchaseFailureResolution()
        case .resultSyncFailure:
            return .matchedOffering(TestData.offeringWithNoIntroOffer)
        case .successfulWorkflow:
            return CheckpointE2EFixtures.successfulWorkflowResolution()
        case .noMatch:
            return .noAction(.noMatch)
        }
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
