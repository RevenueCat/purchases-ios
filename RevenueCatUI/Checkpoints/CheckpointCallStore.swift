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

    enum CallUpdate {
        case outcome(CheckpointExecution)
        case workflowPresentationError(NSError)
        case dismissalReason(WorkflowDismissalReason)
    }

    final class Call {
        let presentation: CheckpointPresentation
        fileprivate(set) var stagedOutcome: CheckpointExecution
        fileprivate(set) var hasReportedOutcome = false
        fileprivate(set) var dismissalReason: WorkflowDismissalReason = .close

        init(
            presentation: CheckpointPresentation,
            stagedOutcome: CheckpointExecution = .completed(customerInfo: nil)
        ) {
            self.presentation = presentation
            self.stagedOutcome = stagedOutcome
        }
    }

    private(set) var call: Call?

    func store(presentation: CheckpointPresentation) {
        self.call = Call(presentation: presentation)
    }

    func stage(_ update: CallUpdate) {
        guard let call = self.call else { return }

        switch update {
        case let .outcome(outcome):
            // Once the customer has purchased or restored, a later non-success outcome must not erase it.
            // A later purchase or restore may replace it with newer CustomerInfo.
            guard !call.stagedOutcome.hasCustomerInfo || outcome.hasCustomerInfo else {
                return
            }
            call.stagedOutcome = outcome
            call.hasReportedOutcome = true
        case let .workflowPresentationError(error):
            // A workflow error does not supersede an outcome that was already reported by the customer.
            guard !call.hasReportedOutcome else { return }
            Logger.error(error.localizedDescription)
            call.stagedOutcome = .failed
            call.hasReportedOutcome = true
        case let .dismissalReason(reason):
            call.dismissalReason = reason
        }
    }

    func remove() -> Call? {
        defer { self.call = nil }
        return self.call
    }

}
