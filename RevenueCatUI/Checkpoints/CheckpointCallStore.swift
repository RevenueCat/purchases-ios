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
        let workflow: ResolvedCheckpointWorkflow
        let delegate: CheckpointPresentationDelegate
        fileprivate(set) var stagedOutcome: CheckpointPaywallOutcome

        init(
            workflow: ResolvedCheckpointWorkflow,
            delegate: CheckpointPresentationDelegate,
            stagedOutcome: CheckpointPaywallOutcome = CheckpointPaywallDismissedOutcome.shared
        ) {
            self.workflow = workflow
            self.delegate = delegate
            self.stagedOutcome = stagedOutcome
        }
    }

    private(set) var call: Call?

    func store(
        workflow: ResolvedCheckpointWorkflow,
        delegate: CheckpointPresentationDelegate
    ) {
        self.call = Call(workflow: workflow, delegate: delegate)
    }

    func stage(outcome: CheckpointPaywallOutcome) {
        self.call?.stagedOutcome = outcome
    }

    func remove() -> Call? {
        defer { self.call = nil }
        return self.call
    }

}
