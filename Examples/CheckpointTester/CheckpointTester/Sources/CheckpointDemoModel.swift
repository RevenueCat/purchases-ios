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

    func showOutcome(_ result: FlowResult?, checkpointIdentifier: String) {
        guard let result else {
            self.showOutcomeAlert(
                title: "No completed flow",
                message: "Checkpoint · \(checkpointIdentifier)\n\n" +
                    "No matching flow was found, or the flow could not complete."
            )
            return
        }

        let identifiers = result.obtainedEntitlements.map(\.entitlementInfo.identifier).sorted()
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

}
