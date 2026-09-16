//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointEventDataTests.swift

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class CheckpointEventDataTests: TestCase {

    private let date = Date(timeIntervalSince1970: 1_699_270_688.995)

    func testMatchedWorkflowReportsPresentUIWithTheWorkflow() throws {
        let workflow = Self.workflow(id: "wf_123")
        let resolved = ResolvedCheckpoint(
            .matchedWorkflow(.init(workflow: workflow,
                                   uiConfig: .empty,
                                   offerings: Self.offerings)),
            checkpointRuleID: "rule_123"
        )

        let data = CheckpointEvent.Data(identifier: "onboarding_complete", date: self.date, resolved: resolved)

        expect(data.result) == .presentUI
        expect(data.workflowID) == "wf_123"
        expect(data.checkpointRuleID) == "rule_123"
        expect(data.offeringID).to(beNil())
    }

    func testMatchedOfferingReportsReturnDataWithTheOffering() throws {
        let resolved = ResolvedCheckpoint(.matchedOffering(Self.offering), checkpointRuleID: "rule_123")

        let data = CheckpointEvent.Data(identifier: "onboarding_complete", date: self.date, resolved: resolved)

        expect(data.result) == .returnData
        expect(data.offeringID) == "onboarding"
        expect(data.checkpointRuleID) == "rule_123"
        expect(data.workflowID).to(beNil())
    }

    func testEachNoActionReasonMapsToItsResult() throws {
        let expected: [CheckpointResolutionReason: CheckpointHitResult] = [
            .noMatch: .noMatch,
            .configurationUnavailable: .configurationUnavailable,
            .unknownCheckpoint: .unknownCheckpoint
        ]

        for (reason, result) in expected {
            let data = CheckpointEvent.Data(identifier: "onboarding_complete",
                                            date: self.date,
                                            resolved: .init(.noAction(reason)))

            expect(data.result) == result
            expect(data.workflowID).to(beNil())
            expect(data.offeringID).to(beNil())
            expect(data.checkpointRuleID).to(beNil())
        }
    }

    func testEveryHitIsCustom() throws {
        let data = CheckpointEvent.Data(identifier: "onboarding_complete",
                                        date: self.date,
                                        resolved: .init(.noAction(.noMatch)))

        expect(data.checkpointType) == .custom
    }

    // MARK: - Helpers

    private static let offering = Offering(
        identifier: "onboarding",
        serverDescription: "Onboarding offering",
        availablePackages: [],
        webCheckoutUrl: nil
    )

    private static var offerings: Offerings {
        let response = OfferingsResponse(
            currentOfferingId: nil,
            offerings: [],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )

        return Offerings(
            offerings: [Self.offering.identifier: Self.offering],
            currentOfferingID: nil,
            placements: nil,
            targeting: nil,
            contents: Offerings.Contents(response: response, httpResponseOriginalSource: .mainServer),
            loadedFromDiskCache: false
        )
    }

    private static func workflow(id: String) -> PublishedWorkflow {
        return PublishedWorkflow(
            id: id,
            displayName: "Test",
            initialStepId: "step_1",
            singleStepFallbackId: nil,
            steps: [:],
            screens: [:]
        )
    }

}
