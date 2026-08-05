//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointDemoModel.swift
//
//  Created by Rick van der Linden.
//

import Combine
import Foundation
@_spi(Internal) import RevenueCat
@_spi(Internal) import RevenueCatUI

final class CheckpointDemoModel: ObservableObject {

    struct OutcomeAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Published private(set) var outcomeAlert: OutcomeAlert?

    private var pendingOutcomeAlerts: [OutcomeAlert] = []

    // MARK: - New checkpoint public API implementation

    // This call is the core integration an app makes when it reaches a checkpoint.
    func runCheckpoint(identifier: String) {
        Task { @MainActor in
            do {
                let result = try await Purchases.shared.checkpoint(
                    identifier,
                    params: CheckpointParams(customProperties: ["name": "Rick"])
                )
                self.showOutcomeAlert(
                    title: "Checkpoint result",
                    message: Self.describe(result)
                )
            } catch {
                self.showOutcomeAlert(
                    title: "Checkpoint failed",
                    message: error.localizedDescription
                )
            }
        }
    }

    // MARK: - Demo-only result presentation

    private func showOutcomeAlert(
        title: String,
        message: String
    ) {
        self.pendingOutcomeAlerts.append(
            OutcomeAlert(title: title, message: message)
        )
        self.presentNextOutcomeAlertIfNeeded()
    }

    func outcomeAlertDismissed() {
        guard self.outcomeAlert != nil else {
            return
        }

        self.outcomeAlert = nil
        DispatchQueue.main.async {
            self.presentNextOutcomeAlertIfNeeded()
        }
    }

    private func presentNextOutcomeAlertIfNeeded() {
        guard self.outcomeAlert == nil, !self.pendingOutcomeAlerts.isEmpty else {
            return
        }
        self.outcomeAlert = self.pendingOutcomeAlerts.removeFirst()
    }

    private static func describe(_ result: CheckpointResult) -> String {
        switch result {
        case let presented as CheckpointPaywallPresentedResult:
            return "Paywall presented · \(presented.checkpoint.identifier)\n\n" +
                "Paywall outcome: \(Self.describe(presented.paywallOutcome))"
        case let noAction as CheckpointNoActionResult:
            return "No action · \(noAction.checkpoint.identifier) · \(noAction.reason.value)"
        default:
            return "Unknown checkpoint result · \(result.checkpoint.identifier)"
        }
    }

    private static func describe(_ result: CheckpointPaywallOutcome) -> String {
        switch result {
        case is CheckpointPaywallDismissedOutcome:
            return "Dismissed"
        case is CheckpointPaywallPurchasedOutcome:
            return "Purchased"
        case is CheckpointPaywallRestoredOutcome:
            return "Restored"
        case let error as CheckpointPaywallErrorOutcome:
            return "Error · \(error.error.localizedDescription)"
        default:
            return "Unknown paywall outcome"
        }
    }

}
