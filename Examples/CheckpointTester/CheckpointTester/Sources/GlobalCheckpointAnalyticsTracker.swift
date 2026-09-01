//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GlobalCheckpointAnalyticsTracker.swift
//
//  Created by Rick van der Linden.
//

import Combine
import Foundation
import OSLog
import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI

/// Example app-wide analytics consumer for the SDK's global checkpoint listener API.
final class GlobalCheckpointAnalyticsTracker: ObservableObject, CheckpointListener {

    @Published private(set) var events: [String] = []

    private static let logger = Logger(
        subsystem: "com.revenuecat.CheckpointTester",
        category: "GlobalCheckpointListener"
    )

    // MARK: - New checkpoint public API implementation

    // These callbacks demonstrate an app-wide analytics integration using CheckpointListener.
    func onCheckpointHit(_ context: CheckpointHitContext) {
        self.track(
            "Hit · \(context.identifier) · customVariables=\(context.customVariables)"
        )
    }

    func onCheckpointCompleted(_ context: CheckpointCompletedContext) {
        self.track(
            "Completed · \(context.identifier) · \(Self.describe(context.result)) · " +
                "customVariables=\(context.customVariables)"
        )
    }

    // MARK: - Demo-only event display

    func clearEvents() {
        self.events.removeAll()
    }

    private func track(_ event: String) {
        let timestamp = Date.now.formatted(date: .omitted, time: .standard)
        self.events.append("\(timestamp) · \(event)")
        Self.logger.info("\(event, privacy: .public)")
    }

    private static func describe(_ result: CheckpointResult) -> String {
        switch result {
        case let presented as CheckpointResult.PaywallPresented:
            return "Paywall presented · \(Self.describe(presented.paywallOutcome))"
        case let received as CheckpointResult.ReceivedOffering:
            return "Received offering · \(received.offering.identifier)"
        case let noAction as CheckpointResult.NoAction:
            return "No action · \(noAction.reason)"
        default:
            return "Unknown result"
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
