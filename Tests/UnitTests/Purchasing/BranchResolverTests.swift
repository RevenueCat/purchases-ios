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
                routes: [
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
            .init(routes: [.init(audienceId: "aud_a", stepId: "step_a")], fallbackStepId: "step_fallback")
        )

        expect(resolved) == "step_fallback"
    }

    func testAnUnreadableAudienceDoesNotStopALaterOneFromWinning() async {
        self.audiencesProvider.rulesByAudienceID = ["aud_b": Self.alwaysMatches]

        let resolved = await self.makeResolver().resolve(
            .init(
                routes: [
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
            .init(routes: [.init(audienceId: "aud_a", stepId: "step_a")], fallbackStepId: "step_fallback")
        )

        expect(resolved) == "step_fallback"
    }

    func testABranchWithNoRoutesNeverReadsTheConfiguration() async {
        let resolved = await self.makeResolver().resolve(
            .init(routes: [], fallbackStepId: "step_fallback")
        )

        expect(resolved) == "step_fallback"
        expect(self.audiencesProvider.configurationRequestCount) == 0
    }

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
