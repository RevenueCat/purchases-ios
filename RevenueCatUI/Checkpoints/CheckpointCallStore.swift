//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointCallStore.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

/// Owns checkpoint presentation state until the UI has fully dismissed.
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointCallStore {

    final class Call {
        let presentation: CheckpointPresentation
        let delegate: CheckpointPresentationDelegate
        fileprivate(set) var stagedOutcome: CheckpointPaywallOutcome

        init(
            presentation: CheckpointPresentation,
            delegate: CheckpointPresentationDelegate,
            stagedOutcome: CheckpointPaywallOutcome = CheckpointPaywallDismissedOutcome.shared
        ) {
            self.presentation = presentation
            self.delegate = delegate
            self.stagedOutcome = stagedOutcome
        }
    }

    private(set) var call: Call?

    func store(
        presentation: CheckpointPresentation,
        delegate: CheckpointPresentationDelegate
    ) {
        self.call = Call(presentation: presentation, delegate: delegate)
    }

    func stage(outcome: CheckpointPaywallOutcome) {
        self.call?.stagedOutcome = outcome
    }

    func remove() -> Call? {
        defer { self.call = nil }
        return self.call
    }

}
