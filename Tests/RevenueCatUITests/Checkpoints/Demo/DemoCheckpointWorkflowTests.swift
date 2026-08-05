//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DemoCheckpointWorkflowTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class DemoCheckpointWorkflowTests: TestCase {

    func testDecodesMultiPageWorkflow() throws {
        let data = Data(
            #"""
            {
              "id": "onboarding",
              "presentation": { "dismissible": true },
              "pages": [
                {
                  "components": [
                    { "type": "title", "text": "Welcome" },
                    { "type": "image", "system_name": "hand.wave.fill" }
                  ],
                  "actions": [
                    { "title": "Continue", "type": "next", "style": "primary" }
                  ]
                },
                {
                  "components": [{ "type": "body", "text": "Done" }],
                  "actions": [
                    { "title": "Finish", "type": "complete", "style": "primary" }
                  ]
                }
              ]
            }
            """#.utf8
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let workflow = try decoder.decode(CheckpointWorkflow.self, from: data)

        XCTAssertEqual(workflow.id, "onboarding")
        XCTAssertTrue(workflow.presentation.dismissible)
        XCTAssertEqual(workflow.pages.count, 2)
        XCTAssertEqual(workflow.pages[0].components[1].systemName, "hand.wave.fill")
        XCTAssertEqual(workflow.pages[1].actions[0].type, .complete)
    }

    func testPresenterReportsResultWhenWorkflowFinishes() {
        let presenter = DemoCheckpointWorkflowPresenter(presentationHandler: { _ in true })
        let delegate = DemoMockCheckpointPresenterDelegate()
        let checkpoint = CheckpointEngineInfo(identifier: "test_checkpoint", params: .init())

        presenter.present(
            callID: "call-id",
            presentation: DemoCheckpointWorkflowPresentation(
                checkpoint: checkpoint,
                workflowData: Self.validWorkflowData
            ),
            delegate: delegate
        )
        presenter.finish(with: .dismissed)

        XCTAssertEqual(delegate.finishedCallID, "call-id")
        guard case .dismissed = delegate.outcome else {
            return XCTFail("Expected a dismissed outcome")
        }
    }

    private static let validWorkflowData = Data(
        #"""
        {
          "id": "workflow",
          "presentation": { "dismissible": true },
          "pages": [
            {
              "components": [{ "type": "title", "text": "Title" }],
              "actions": [{ "title": "Done", "type": "dismiss", "style": "primary" }]
            }
          ]
        }
        """#.utf8
    )

}

private final class DemoMockCheckpointPresenterDelegate: CheckpointEnginePresenterDelegate {

    private(set) var finishedCallID: String?
    private(set) var outcome: CheckpointEnginePaywallOutcome?

    func onCheckpointPaywallFinished(callID: String, outcome: CheckpointEnginePaywallOutcome) {
        self.finishedCallID = callID
        self.outcome = outcome
    }

}
