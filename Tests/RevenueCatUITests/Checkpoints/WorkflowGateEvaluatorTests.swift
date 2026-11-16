//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowGateEvaluatorTests.swift
//

@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WorkflowGateEvaluatorTests: TestCase {

    private let hardGate = WorkflowStepGating.hard(entitlementIdentifiers: ["pro", "premium"])

    func testHardGateIsSatisfiedByAnyConfiguredEntitlement() {
        XCTAssertTrue(self.hardGate.isSatisfied(by: ["premium"]))
    }

    func testHardGateIsNotSatisfiedByUnrelatedEntitlements() {
        XCTAssertFalse(self.hardGate.isSatisfied(by: ["unrelated"]))
    }

    func testHardGateIsNotSatisfiedWithoutActiveEntitlements() {
        XCTAssertFalse(self.hardGate.isSatisfied(by: []))
    }

    func testSoftGateIsSatisfiedWithoutActiveEntitlements() {
        XCTAssertTrue(WorkflowStepGating.soft.isSatisfied(by: []))
    }

    func testInvalidGateFailsClosedEvenWithActiveEntitlements() {
        XCTAssertFalse(WorkflowStepGating.invalid.isSatisfied(by: ["pro", "premium"]))
    }

    func testOnlyHardAndInvalidGatesAreEnforced() {
        XCTAssertTrue(self.hardGate.isEnforced)
        XCTAssertTrue(WorkflowStepGating.invalid.isEnforced)
        XCTAssertFalse(WorkflowStepGating.soft.isEnforced)
    }

}
