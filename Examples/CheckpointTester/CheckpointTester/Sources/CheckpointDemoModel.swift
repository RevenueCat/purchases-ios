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
import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI

enum PaywallPresenterMode: String, CaseIterable, Identifiable {
    case `default`
    case global
    case localOverride

    var id: Self { self }

    var title: String {
        switch self {
        case .default: return "Default"
        case .global: return "Global"
        case .localOverride: return "Local"
        }
    }

    var description: String {
        switch self {
        case .default:
            return "For an offering step, RevenueCat presents its default paywall."
        case .global:
            return "For an offering step, Purchases.shared uses the blue global presenter."
        case .localOverride:
            return "For an offering step, each checkpoint call uses the purple local override."
        }
    }
}

final class CheckpointDemoModel: ObservableObject {

    struct OutcomeAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Published private(set) var outcomeAlert: OutcomeAlert?
    @Published var paywallPresenterMode: PaywallPresenterMode = .default

    private var pendingOutcomeAlerts: [OutcomeAlert] = []

    func showOutcome(_ result: CheckpointResult, checkpointIdentifier: String) {
        self.showOutcomeAlert(
            title: "Checkpoint result",
            message: Self.describe(result, checkpointIdentifier: checkpointIdentifier)
        )
    }

    func showOutcome(_ result: CheckpointFlowResult?, checkpointIdentifier: String) {
        guard let result else {
            self.showOutcomeAlert(
                title: "No completed flow",
                message: "Checkpoint · \(checkpointIdentifier)\n\n" +
                    "No matching flow was found, or the flow could not complete."
            )
            return
        }

        let identifiers = result.obtainedEntitlements.map(\.entitlement.identifier).sorted()
        self.showOutcomeAlert(
            title: "Checkpoint completed",
            message: identifiers.isEmpty
                ? "Checkpoint · \(checkpointIdentifier)\n\nNo active entitlements reported."
                : "Checkpoint · \(checkpointIdentifier)\n\nObtained: \(identifiers.joined(separator: ", "))"
        )
    }

    func showError(_ error: Error) {
        self.showOutcomeAlert(
            title: "Checkpoint failed",
            message: error.localizedDescription
        )
    }

    @MainActor
    func configurePaywallPresenter() {
        Purchases.shared.checkpointPaywallPresenter = switch self.paywallPresenterMode {
        case .global: GlobalPaywallPresenter.shared
        case .default, .localOverride: nil
        }
    }

    @MainActor
    var localPaywallPresenter: PaywallPresentationHandler? {
        guard self.paywallPresenterMode == .localOverride else { return nil }
        return LocalPaywallPresenter.shared
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

    private static func describe(_ result: CheckpointResult, checkpointIdentifier: String) -> String {
        switch result {
        case let presented as CheckpointResult.PaywallPresented:
            return "Paywall presented · \(checkpointIdentifier)\n\n" +
                "Paywall outcome: \(Self.describe(presented.paywallOutcome))"
        case let received as CheckpointResult.ReceivedOffering:
            return "Received offering · \(checkpointIdentifier) · \(received.offering.identifier)"
        case let noAction as CheckpointResult.NoAction:
            return "No action · \(checkpointIdentifier) · \(noAction.reason)"
        default:
            return "Unknown checkpoint result · \(checkpointIdentifier)"
        }
    }

    private static func describe(_ result: CheckpointPaywallOutcome) -> String {
        switch result {
        case is CheckpointPaywallOutcome.Dismissed:
            return "Dismissed"
        case is CheckpointPaywallOutcome.WebCheckoutOpened:
            return "Web checkout opened"
        case is CheckpointPaywallOutcome.Purchased:
            return "Purchased"
        case is CheckpointPaywallOutcome.Restored:
            return "Restored"
        case let error as CheckpointPaywallOutcome.Error:
            return "Error · \(error.error.localizedDescription)"
        default:
            return "Unknown paywall outcome"
        }
    }

}
