//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPresentationSlotTests.swift
//
//  Created by Rick van der Linden.
//

@_spi(CheckpointsInternal) @testable import RevenueCatUI
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointPresentationSlotTests: TestCase {

    func testFirstClaimOwnsTheSlot() throws {
        let slot = CheckpointPresentationSlot()
        let token = try XCTUnwrap(slot.claim())

        XCTAssertTrue(slot.contains(token))
        XCTAssertNil(slot.claim())
    }

    func testMatchingReleaseFreesTheSlot() throws {
        let slot = CheckpointPresentationSlot()
        let token = try XCTUnwrap(slot.claim())

        XCTAssertTrue(slot.release(token))
        XCTAssertFalse(slot.contains(token))
        XCTAssertNotNil(slot.claim())
    }

    func testStaleTokenCannotReleaseReplacementClaim() throws {
        let slot = CheckpointPresentationSlot()
        let staleToken = try XCTUnwrap(slot.claim())
        XCTAssertTrue(slot.release(staleToken))
        let replacementToken = try XCTUnwrap(slot.claim())

        XCTAssertFalse(slot.release(staleToken))
        XCTAssertTrue(slot.contains(replacementToken))
        XCTAssertNil(slot.claim())
    }

    func testDuplicateReleaseIsIgnored() throws {
        let slot = CheckpointPresentationSlot()
        let token = try XCTUnwrap(slot.claim())

        XCTAssertTrue(slot.release(token))
        XCTAssertFalse(slot.release(token))
    }

}
