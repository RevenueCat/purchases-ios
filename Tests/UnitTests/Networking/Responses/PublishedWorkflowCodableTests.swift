//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PublishedWorkflowCodableTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

/// `PublishedWorkflow`'s `Codable` conformance is hand-written, not synthesized, so a decode/encode
/// mismatch is no longer ruled out for free — these tests catch that.
class PublishedWorkflowCodableTests: TestCase {

    func testEncodeThenDecodeRoundTripsAllFields() throws {
        let original = PublishedWorkflow(
            id: "wf-1",
            displayName: "Test workflow",
            initialStepId: "step-1",
            singleStepFallbackId: "step-2",
            steps: [:],
            screens: [:],
            uiConfig: .empty,
            contentMaxWidth: 400
        )

        let data = try JSONEncoder.default.encode(value: original)
        let decoded = try JSONDecoder.default.decode(PublishedWorkflow.self, jsonData: data)

        expect(decoded) == original
    }

    func testDecodingWithoutUiConfigDefaultsToEmpty() throws {
        let json = """
        {
          "id": "wf-1",
          "display_name": "Test",
          "initial_step_id": "step-1",
          "steps": {},
          "screens": {}
        }
        """
        let decoded = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            jsonData: try XCTUnwrap(json.data(using: .utf8))
        )

        expect(decoded.uiConfig) == .empty
    }

    func testDecodingWithMetadataPreservesIt() throws {
        let json = """
        {
          "id": "wf-1",
          "display_name": "Test",
          "initial_step_id": "step-1",
          "steps": {},
          "screens": {},
          "metadata": { "source": "cdn" }
        }
        """
        let decoded = try JSONDecoder.default.decode(
            PublishedWorkflow.self,
            jsonData: try XCTUnwrap(json.data(using: .utf8))
        )

        expect(decoded.metadata?["source"]) == .string("cdn")
    }

}
