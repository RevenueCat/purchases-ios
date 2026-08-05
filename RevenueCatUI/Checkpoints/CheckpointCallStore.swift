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
final class CheckpointCallStore {

    final class Call {
        let presentation: ResolvedCheckpointWorkflowPresentation
        let delegate: CheckpointEnginePresenterDelegate
        fileprivate(set) var stagedOutcome: CheckpointPaywallOutcome

        init(
            presentation: ResolvedCheckpointWorkflowPresentation,
            delegate: CheckpointEnginePresenterDelegate,
            stagedOutcome: CheckpointPaywallOutcome = CheckpointPaywallDismissedOutcome.shared
        ) {
            self.presentation = presentation
            self.delegate = delegate
            self.stagedOutcome = stagedOutcome
        }
    }

    private var calls: [String: Call] = [:]

    func store(
        callID: String,
        presentation: ResolvedCheckpointWorkflowPresentation,
        delegate: CheckpointEnginePresenterDelegate
    ) {
        self.calls[callID] = Call(presentation: presentation, delegate: delegate)
    }

    func call(for callID: String) -> Call? {
        return self.calls[callID]
    }

    func stage(outcome: CheckpointPaywallOutcome, for callID: String) {
        self.calls[callID]?.stagedOutcome = outcome
    }

    func remove(callID: String) -> Call? {
        return self.calls.removeValue(forKey: callID)
    }

}
