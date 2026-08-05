//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowPresenterTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class CheckpointWorkflowPresenterTests: TestCase {

    func testRuntimePresenterProviderCanBeDiscovered() throws {
        #if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        let provider = try XCTUnwrap(
            NSClassFromString("RCCheckpointPresenterProvider") as? CheckpointPresenterProvider.Type
        )

        XCTAssertTrue(provider.makeCheckpointPresenter() is CheckpointWorkflowPresenter)
        #endif
    }

    func testPresenterRejectsAnUnresolvedPresentation() {
        let presenter = CheckpointWorkflowPresenter()
        let delegate = MockCheckpointPresenterDelegate()
        let checkpoint = CheckpointInfo(identifier: "test_checkpoint", params: CheckpointParams())

        presenter.present(
            callID: "call-id",
            presentation: CheckpointWorkflowPresentation(checkpoint: checkpoint),
            delegate: delegate
        )

        XCTAssertEqual(delegate.finishedCallID, "call-id")
        XCTAssertTrue(delegate.outcome is CheckpointPaywallErrorOutcome)
    }

}

private final class MockCheckpointPresenterDelegate: CheckpointPresenterDelegate {

    private(set) var finishedCallID: String?
    private(set) var outcome: CheckpointPaywallOutcome?

    func onCheckpointPaywallFinished(callID: String, outcome: CheckpointPaywallOutcome) {
        self.finishedCallID = callID
        self.outcome = outcome
    }

}
