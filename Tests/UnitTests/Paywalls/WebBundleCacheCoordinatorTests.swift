//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleCacheCoordinatorTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/11/26.
//

@_spi(Internal) @testable import RevenueCat
import XCTest

final class WebBundleCacheCoordinatorTests: TestCase {

    func testSweepRemovesIdentifiersThatExistAndWereDeleted() async {
        let first = UUID()
        let second = UUID()
        var removed: [UUID] = []

        let remaining = await WebBundleCacheCoordinator.sweep(
            pending: [first, second],
            existing: [first, second],
            remove: { identifier in
                removed.append(identifier)
                return true
            }
        )

        XCTAssertEqual(Set(removed), [first, second])
        XCTAssertTrue(remaining.isEmpty)
    }

    func testSweepKeepsIdentifiersWhenRemoveFails() async {
        let identifier = UUID()

        let remaining = await WebBundleCacheCoordinator.sweep(
            pending: [identifier],
            existing: [identifier],
            remove: { _ in false }
        )

        XCTAssertEqual(remaining, [identifier])
    }

    func testSweepDropsMissingIdentifiersWithoutCallingRemove() async {
        let identifier = UUID()
        var removeCalled = false

        let remaining = await WebBundleCacheCoordinator.sweep(
            pending: [identifier],
            existing: [],
            remove: { _ in
                removeCalled = true
                return true
            }
        )

        XCTAssertFalse(removeCalled)
        XCTAssertTrue(remaining.isEmpty)
    }

}
