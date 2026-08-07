//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointRulesTests.swift
//
//  Created by Facundo Menzella.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

/// Decoding tests for a checkpoint's payload, run through `JSONDecoder.default` so the key and date
/// strategies the topic manager uses are exercised for real.
final class CheckpointRulesTests: TestCase {

    // MARK: - Wire contract

    func testDecodesTheDocumentedExamplePayload() throws {
        let ruleSet = try Self.decode("""
        {
          "id": "chkpt_a1b2c3d4e5f6a7b8",
          "rules": [
            {
              "id": "chkptrule_1a2b3c4d5e6f7a8b",
              "audience": "aud_4412",
              "workflow_id": "wf-1"
            },
            {
              "id": "chkptrule_9z8y7x6w5v4u3t2s",
              "audience": "aud_4419",
              "workflow_id": "wf-2"
            }
          ]
        }
        """)

        expect(ruleSet.id) == "chkpt_a1b2c3d4e5f6a7b8"
        expect(ruleSet.rules.map(\.workflowId)) == ["wf-1", "wf-2"]

        let first = try XCTUnwrap(ruleSet.rules.first)
        expect(first.id) == "chkptrule_1a2b3c4d5e6f7a8b"
        expect(first.audienceId) == "aud_4412"

        expect(ruleSet.rules.last?.audienceId) == "aud_4419"
    }

    func testDecodesACheckpointWithNoRules() throws {
        let ruleSet = try Self.decode(#"{ "id": "chkpt_abc" }"#)

        expect(ruleSet.id) == "chkpt_abc"
        expect(ruleSet.rules).to(beEmpty())
    }

    func testIgnoresUnknownFields() throws {
        let ruleSet = try Self.decode("""
        {
          "id": "chkpt_abc",
          "something_the_backend_added_later": true,
          "rules": [{ "audience": "aud_4412", "workflow_id": "wf-a", "state": "active", "frequency_cap": null }]
        }
        """)

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-a"]
    }

    func testThrowsForAPayloadThatIsntAJSONObject() {
        expect { try Self.decode("not-json") }.to(throwError())
        expect { try Self.decode(#"["an", "array"]"#) }.to(throwError())
    }

    // MARK: - Ordering

    /// Rules are served in priority order, so decoding must not reorder them.
    func testPreservesTheServedRuleOrder() throws {
        let ruleSet = try Self.decode("""
        { "rules": [\(Self.rule("wf-c")), \(Self.rule("wf-a")), \(Self.rule("wf-b"))] }
        """)

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-c", "wf-a", "wf-b"]
    }

    // MARK: - Skipping malformed rules

    /// One bad rule shouldn't take out the whole checkpoint, and it shouldn't shift the others either.
    func testSkipsAMalformedRuleAndKeepsTheRest() throws {
        let ruleSet = try Self.decode("""
        { "rules": [\(Self.rule("wf-a")), { "audience": "aud_4412" }, \(Self.rule("wf-b"))] }
        """)

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-a", "wf-b"]
    }

    func testSkipsRulesMissingAnAudience() throws {
        let ruleSet = try Self.decode("""
        { "rules": [{ "workflow_id": "wf-no-audience" }, \(Self.rule("wf-valid"))] }
        """)

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-valid"]
    }

    func testSkipsRulesMissingAWorkflowId() throws {
        let ruleSet = try Self.decode("""
        { "rules": [{ "audience": "aud_4412" }, \(Self.rule("wf-valid"))] }
        """)

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-valid"]
    }

    func testSkipsRuleEntriesThatArentObjects() throws {
        let ruleSet = try Self.decode("""
        { "rules": ["not-a-rule", \(Self.rule("wf-valid"))] }
        """)

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-valid"]
    }

    // MARK: - Helpers

    private static func decode(_ json: String) throws -> CheckpointRuleSet {
        return try JSONDecoder.default.decode(CheckpointRuleSet.self, from: Data(json.utf8))
    }

    private static func rule(_ workflowId: String) -> String {
        return #"{ "audience": "aud_4412", "workflow_id": "\#(workflowId)" }"#
    }

}
