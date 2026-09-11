//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointCallStoreTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(CheckpointsInternal) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointCallStoreTests: TestCase {

    func testErrorDoesNotReplacePurchaseOutcome() {
        let store = CheckpointCallStore()
        let transaction = StoreTransaction(MockStoreTransaction())
        store.store(presentation: Self.presentation(), delegate: Delegate())

        store.stage(.outcome(CheckpointPaywallOutcome.Purchased(
            transaction: transaction,
            customerInfo: TestData.customerInfo
        )))
        store.stage(.outcome(CheckpointPaywallOutcome.Error(error: NSError(domain: "test", code: 1))))

        guard let outcome = store.call?.stagedOutcome as? CheckpointPaywallOutcome.Purchased else {
            return XCTFail("Expected the earlier purchase outcome to win")
        }
        XCTAssertEqual(outcome.transaction, transaction)
        XCTAssertEqual(outcome.customerInfo, TestData.customerInfo)
    }

    func testErrorDoesNotReplaceRestoreOutcome() {
        let store = CheckpointCallStore()
        store.store(presentation: Self.presentation(), delegate: Delegate())

        store.stage(.outcome(CheckpointPaywallOutcome.Restored(customerInfo: TestData.customerInfo)))
        store.stage(.outcome(CheckpointPaywallOutcome.Error(error: NSError(domain: "test", code: 1))))

        guard let outcome = store.call?.stagedOutcome as? CheckpointPaywallOutcome.Restored else {
            return XCTFail("Expected the earlier restore outcome to win")
        }
        XCTAssertEqual(outcome.customerInfo, TestData.customerInfo)
    }

    private static func presentation() -> CheckpointPresentation {
        return .init(
            workflow: ResolvedCheckpointWorkflow(
                workflow: PublishedWorkflow(
                    id: "workflow-id",
                    displayName: "Test",
                    initialStepId: "step-id",
                    singleStepFallbackId: nil,
                    steps: [:],
                    screens: [:]
                ),
                uiConfig: .empty,
                offerings: .preview(offerings: [])
            ),
            customVariables: [:]
        )
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class Delegate: CheckpointPresentationDelegate {

    func checkpointPresentationFinished(_ execution: CheckpointExecutionResult<CheckpointPaywallOutcome>) {}

}
