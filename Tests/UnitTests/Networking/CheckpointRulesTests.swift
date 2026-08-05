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

final class CheckpointRulesTests: TestCase {

    // MARK: - Wire contract

    func testParsesTheDocumentedExamplePayload() throws {
        let blob = Data("""
        {
          "id": "checkpoint-abc",
          "rules": [
            {
              "id": "rule-1",
              "audience": "audience-1",
              "workflow_id": "wf-1",
              "frequency_cap": { "type": "once" },
              "schedule": { "start": "2026-11-25T00:00:00Z", "end": "2026-11-30T00:00:00Z" }
            },
            {
              "id": "rule-2",
              "audience": "audience-2",
              "workflow_id": "wf-2",
              "frequency_cap": { "type": "every" }
            }
          ]
        }
        """.utf8)
        let ruleSet = try XCTUnwrap(CheckpointRuleSet.parse(identifier: "app_open", blob: blob))

        expect(ruleSet.identifier) == "app_open"
        expect(ruleSet.id) == "checkpoint-abc"
        expect(ruleSet.rules.map(\.workflowId)) == ["wf-1", "wf-2"]

        let first = try XCTUnwrap(ruleSet.rules.first)
        expect(first.id) == "rule-1"
        expect(first.audienceId) == "audience-1"
        expect(first.frequencyCap) == CheckpointFrequencyCap(type: "once")
        expect(first.schedule?.start) == Self.date("2026-11-25T00:00:00Z")
        expect(first.schedule?.end) == Self.date("2026-11-30T00:00:00Z")

        let second = try XCTUnwrap(ruleSet.rules.last)
        expect(second.frequencyCap) == CheckpointFrequencyCap(type: "every")
        expect(second.schedule).to(beNil())
    }

    func testKeepsPayloadKeysVerbatimWhileItemMetadataIsCamelCased() throws {
        let blob = Data(#"{ "rules": [{ "workflow_id": "wf-1", "frequency_cap": { "type": "once" } }] }"#.utf8)
        let ruleSet = try XCTUnwrap(CheckpointRuleSet.parse(identifier: "app_open", blob: blob))

        let rule = try XCTUnwrap(ruleSet.rules.onlyElement)
        expect(rule.workflowId) == "wf-1"
        expect(rule.frequencyCap) == CheckpointFrequencyCap(type: "once")

        let payload = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.checkpoints:etag",
          "active_topics": ["checkpoints"],
          "topics": {
            "checkpoints": {
              "app_open": { "blob_ref": "app-open-ref", "prefetch": true, "first_seen": "2026-06-17T08:44:26Z" }
            }
          }
        }
        """
        let response = try JSONDecoder.default.decode(RemoteConfiguration.self, from: Data(payload.utf8))
        let item = try XCTUnwrap(
            response.topics.entries[RemoteConfigTopic.checkpoints.wireName]?["app_open"]
        )

        expect(item.blobRef) == "app-open-ref"
        expect(item.prefetch) == true
        expect(item.content.keys.sorted()) == ["firstSeen"]
    }

    func testReturnsNilForAPayloadThatIsntAJSONObject() {
        expect(CheckpointRuleSet.parse(identifier: "app_open", blob: Data("not-json".utf8))).to(beNil())
        expect(CheckpointRuleSet.parse(identifier: "app_open", blob: Data(#"["an", "array"]"#.utf8))).to(beNil())
    }

    // MARK: - Ordering

    func testPreservesTheServedRuleOrder() {
        let ruleSet = Self.ruleSet(["rules": .array([
            Self.rule(workflowId: "wf-c"),
            Self.rule(workflowId: "wf-a"),
            Self.rule(workflowId: "wf-b")
        ])])

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-c", "wf-a", "wf-b"]
    }

    func testKeepsServedOrderWhenARuleInTheMiddleIsSkipped() {
        let ruleSet = Self.ruleSet(["rules": .array([
            Self.rule(workflowId: "wf-a"),
            .object(["id": .string("no-workflow")]),
            Self.rule(workflowId: "wf-b")
        ])])

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-a", "wf-b"]
    }

    // MARK: - Malformed data

    func testSkipsRulesMissingAWorkflowId() {
        let ruleSet = Self.ruleSet(["rules": .array([
            .object(["id": .string("rule-1")]),
            Self.rule(workflowId: "wf-valid"),
            .object(["workflow_id": .string("")])
        ])])

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-valid"]
    }

    func testSkipsRuleEntriesThatArentObjects() {
        let ruleSet = Self.ruleSet(["rules": .array([
            .string("not-a-rule"),
            Self.rule(workflowId: "wf-valid")
        ])])

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-valid"]
    }

    func testKeepsCheckpointWithNoRulesWhenRulesArentAnArray() {
        expect(Self.ruleSet(["rules": .string("nope")]).rules).to(beEmpty())
    }

    func testKeepsCheckpointWithNoRulesKeyAtAll() {
        let ruleSet = Self.ruleSet(["id": .string("checkpoint-xyz")])

        expect(ruleSet.identifier) == "app_open"
        expect(ruleSet.id) == "checkpoint-xyz"
        expect(ruleSet.rules).to(beEmpty())
    }

    func testIgnoresUnknownFields() {
        let ruleSet = Self.ruleSet([
            "something_the_backend_added_later": .bool(true),
            "rules": .array([
                .object([
                    "workflow_id": .string("wf-a"),
                    "state": .string("active"),
                    "something_else_new": .bool(true)
                ])
            ])
        ])

        expect(ruleSet.rules.map(\.workflowId)) == ["wf-a"]
    }

    // MARK: - Optional rule fields

    func testTreatsAnAbsentAudienceAsTargetingEveryone() {
        let ruleSet = Self.ruleSet(["rules": .array([Self.rule(workflowId: "wf-a")])])

        expect(ruleSet.rules.onlyElement?.audienceId).to(beNil())
    }

    func testIgnoresAFrequencyCapWithoutAType() {
        let ruleSet = Self.ruleSet(["rules": .array([
            .object(["workflow_id": .string("wf-a"), "frequency_cap": .object(["count": .int(3)])])
        ])])

        expect(ruleSet.rules.onlyElement?.frequencyCap).to(beNil())
    }

    func testParsesACustomFrequencyCap() {
        let ruleSet = Self.ruleSet(["rules": .array([
            .object([
                "workflow_id": .string("wf-a"),
                "frequency_cap": .object([
                    "type": .string("custom"),
                    "count": .int(3),
                    "window": .string("P7D")
                ])
            ])
        ])])

        expect(ruleSet.rules.onlyElement?.frequencyCap)
            == CheckpointFrequencyCap(type: "custom", count: 3, window: "P7D")
    }

    func testParsesAScheduleWithOnlyOneBound() {
        let ruleSet = Self.ruleSet(["rules": .array([
            .object([
                "workflow_id": .string("wf-a"),
                "schedule": .object(["start": .string("2026-11-25T00:00:00Z")])
            ])
        ])])

        expect(ruleSet.rules.onlyElement?.schedule?.start) == Self.date("2026-11-25T00:00:00Z")
        expect(ruleSet.rules.onlyElement?.schedule?.end).to(beNil())
    }

    /// Dropped rather than kept as open-ended, which would run the rule outside its dates.
    func testDropsAScheduleWhoseDatesCantBeParsed() {
        let ruleSet = Self.ruleSet(["rules": .array([
            .object([
                "workflow_id": .string("wf-a"),
                "schedule": .object(["start": .string("not-a-date"), "end": .string("nope")])
            ])
        ])])

        expect(ruleSet.rules.onlyElement?.workflowId) == "wf-a"
        expect(ruleSet.rules.onlyElement?.schedule).to(beNil())
    }

    func testParsesFractionalSecondsInASchedule() {
        let ruleSet = Self.ruleSet(["rules": .array([
            .object([
                "workflow_id": .string("wf-a"),
                "schedule": .object(["start": .string("2026-11-25T00:00:00.251Z")])
            ])
        ])])

        expect(ruleSet.rules.onlyElement?.schedule?.start) == Self.date("2026-11-25T00:00:00.251Z")
    }

    // MARK: - Helpers

    private static func ruleSet(_ fields: [String: AnyDecodable]) -> CheckpointRuleSet {
        return CheckpointRuleSet.parse(identifier: "app_open", fields: fields)
    }

    private static func rule(workflowId: String) -> AnyDecodable {
        return .object(["workflow_id": .string(workflowId)])
    }

    private static func date(_ string: String) -> Date? {
        return ISO8601DateFormatter.default.date(from: string)
    }

}
