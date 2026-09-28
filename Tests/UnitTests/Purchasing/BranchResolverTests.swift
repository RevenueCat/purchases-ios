//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BranchResolverTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

class BranchResolverTests: TestCase {

    private var audiencesProvider: StubAudiencesConfigProvider!

    override func setUp() {
        super.setUp()
        self.audiencesProvider = StubAudiencesConfigProvider()
    }

    // MARK: - resolve

    func testTheFirstMatchingAudienceDecidesTheRoute() async {
        self.audiencesProvider.rulesByAudienceID = ["aud_a": Self.alwaysMatches, "aud_b": Self.alwaysMatches]

        let resolved = await self.makeResolver().resolve(
            .init(
                branches: [
                    .init(audienceId: "aud_a", stepId: "step_a"),
                    .init(audienceId: "aud_b", stepId: "step_b")
                ],
                fallbackStepId: "step_fallback"
            )
        )

        expect(resolved) == "step_a"
    }

    func testNoMatchingAudienceTakesTheFallback() async {
        self.audiencesProvider.rulesByAudienceID = ["aud_a": Self.neverMatches]

        let resolved = await self.makeResolver().resolve(
            .init(branches: [.init(audienceId: "aud_a", stepId: "step_a")], fallbackStepId: "step_fallback")
        )

        expect(resolved) == "step_fallback"
    }

    func testAnUnreadableAudienceDoesNotStopALaterOneFromWinning() async {
        self.audiencesProvider.rulesByAudienceID = ["aud_b": Self.alwaysMatches]

        let resolved = await self.makeResolver().resolve(
            .init(
                branches: [
                    .init(audienceId: "aud_missing", stepId: "step_a"),
                    .init(audienceId: "aud_b", stepId: "step_b")
                ],
                fallbackStepId: "step_fallback"
            )
        )

        expect(resolved) == "step_b"
    }

    func testAnUnavailableConfigurationTakesTheFallback() async {
        self.audiencesProvider.configurationUnavailable = true

        let resolved = await self.makeResolver().resolve(
            .init(branches: [.init(audienceId: "aud_a", stepId: "step_a")], fallbackStepId: "step_fallback")
        )

        expect(resolved) == "step_fallback"
    }

    func testABranchWithNoRoutesNeverReadsTheConfiguration() async {
        let resolved = await self.makeResolver().resolve(
            .init(branches: [], fallbackStepId: "step_fallback")
        )

        expect(resolved) == "step_fallback"
        expect(self.audiencesProvider.configurationRequestCount) == 0
    }

    // MARK: - resolveBranches

    func testResolveBranchesCoversEveryBranchOnTheStep() async throws {
        self.audiencesProvider.rulesByAudienceID = ["aud_a": Self.alwaysMatches, "aud_b": Self.alwaysMatches]
        let step = try XCTUnwrap(Self.stepWithTwoBranchActions())

        let resolved = await self.makeResolver().resolveBranches(in: step)

        expect(resolved) == ["btn_one": "step_a", "btn_two": "step_b"]
    }

    // MARK: - gate

    // MARK: - disabled

}

// MARK: - Helpers

private extension BranchResolverTests {

    static let alwaysMatches = #"{"==": [1, 1]}"#
    static let neverMatches = #"{"==": [1, 0]}"#

    func makeResolver() -> DefaultBranchResolver {
        return DefaultBranchResolver(
            audiencesConfigProvider: self.audiencesProvider,
            localRulesEvaluator: LocalRulesEvaluator(
                dimensionProviders: [],
                currentAppUserIDProvider: { "user" }
            )
        )
    }

    /// One step whose two buttons each carry their own branch.
    static func stepWithTwoBranchActions() throws -> WorkflowStep {
        let json = """
        {
          "id": "step_1",
          "type": "screen",
          "triggers": [
            {"name":"One","type":"on_press","action_id":"btn_one","component_id":"btn_one"},
            {"name":"Two","type":"on_press","action_id":"btn_two","component_id":"btn_two"}
          ],
          "trigger_actions": {
            "btn_one": {
              "type": "branch",
              "branches": [{"audience_id": "aud_a", "step_id": "step_a"}],
              "fallback_step_id": "step_fallback_1"
            },
            "btn_two": {
              "type": "branch",
              "branches": [{"audience_id": "aud_b", "step_id": "step_b"}],
              "fallback_step_id": "step_fallback_2"
            }
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(WorkflowStep.self, from: data)
    }

}

private final class StubAudiencesConfigProvider: AudiencesConfigProviderType {

    var rulesByAudienceID: [String: String] = [:]
    var configurationUnavailable = false
    private(set) var configurationRequestCount = 0

    func configuration() async throws -> AudienceConfigurationSnapshot? {
        self.configurationRequestCount += 1

        guard !self.configurationUnavailable else { return nil }

        return AudienceConfigurationSnapshot(
            audiences: Dictionary(uniqueKeysWithValues: self.rulesByAudienceID.map { identifier, rules in
                (identifier, Audience(id: identifier, rules: rules))
            }),
            configGeneration: 0
        )
    }

    func isCurrent(_ snapshot: AudienceConfigurationSnapshot) -> Bool {
        return true
    }

}
