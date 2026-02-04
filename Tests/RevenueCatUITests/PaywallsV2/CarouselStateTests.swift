//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CarouselStateTests.swift
//
//  Created by RevenueCat on 2/4/26.

@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
class CarouselStateTests: TestCase {

    // MARK: - isActive Tests

    func testIsActiveReturnsTrueWhenIndicesMatch() {
        let state = CarouselState(activeIndex: 2, pageIndex: 2, originalCount: 5)
        XCTAssertTrue(state.isActive)
    }

    func testIsActiveReturnsFalseWhenIndicesDontMatch() {
        let state = CarouselState(activeIndex: 2, pageIndex: 3, originalCount: 5)
        XCTAssertFalse(state.isActive)
    }

    func testIsActiveHandlesLoopingCarousel() {
        // In a looping carousel with 3 original pages, indices 0, 3, 6 all represent the same page
        let state = CarouselState(activeIndex: 3, pageIndex: 0, originalCount: 3)
        XCTAssertTrue(state.isActive, "Page 0 and page 3 should be the same in a 3-page looping carousel")
    }

    func testIsActiveWithZeroOriginalCountFallsBackToDirectComparison() {
        let state = CarouselState(activeIndex: 2, pageIndex: 2, originalCount: 0)
        XCTAssertTrue(state.isActive)

        let state2 = CarouselState(activeIndex: 2, pageIndex: 3, originalCount: 0)
        XCTAssertFalse(state2.isActive)
    }

    // MARK: - isActiveOrNeighbor Tests

    func testIsActiveOrNeighborReturnsTrueForActiveIndex() {
        let state = CarouselState(activeIndex: 2, pageIndex: 2, originalCount: 5)
        XCTAssertTrue(state.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborReturnsTrueForPreviousPage() {
        let state = CarouselState(activeIndex: 2, pageIndex: 1, originalCount: 5)
        XCTAssertTrue(state.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborReturnsTrueForNextPage() {
        let state = CarouselState(activeIndex: 2, pageIndex: 3, originalCount: 5)
        XCTAssertTrue(state.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborReturnsFalseForDistantPage() {
        let state = CarouselState(activeIndex: 2, pageIndex: 4, originalCount: 5)
        XCTAssertFalse(state.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborHandlesWrapAroundAtEnd() {
        // In a 5-page carousel, when on page 0, page 4 is a neighbor (wrap-around)
        let state = CarouselState(activeIndex: 0, pageIndex: 4, originalCount: 5)
        XCTAssertTrue(state.isActiveOrNeighbor, "Page 4 should be a neighbor of page 0 in a 5-page looping carousel")
    }

    func testIsActiveOrNeighborHandlesWrapAroundAtStart() {
        // In a 5-page carousel, when on page 4, page 0 is a neighbor (wrap-around)
        let state = CarouselState(activeIndex: 4, pageIndex: 0, originalCount: 5)
        XCTAssertTrue(state.isActiveOrNeighbor, "Page 0 should be a neighbor of page 4 in a 5-page looping carousel")
    }

    func testIsActiveOrNeighborWithSinglePageCarousel() {
        let state = CarouselState(activeIndex: 0, pageIndex: 0, originalCount: 1)
        XCTAssertTrue(state.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborWithTwoPageCarousel() {
        // Both pages are always neighbors in a 2-page carousel
        let state1 = CarouselState(activeIndex: 0, pageIndex: 1, originalCount: 2)
        XCTAssertTrue(state1.isActiveOrNeighbor)

        let state2 = CarouselState(activeIndex: 1, pageIndex: 0, originalCount: 2)
        XCTAssertTrue(state2.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborWithThreePageCarouselAllAreNeighbors() {
        // In a 3-page carousel, every page is a neighbor of every other page
        for active in 0..<3 {
            for page in 0..<3 {
                let state = CarouselState(activeIndex: active, pageIndex: page, originalCount: 3)
                XCTAssertTrue(
                    state.isActiveOrNeighbor,
                    "In 3-page carousel, page \(page) should be neighbor of active \(active)"
                )
            }
        }
    }

    func testIsActiveOrNeighborWithZeroOriginalCountFallsBackToDirectDistance() {
        let neighbor = CarouselState(activeIndex: 2, pageIndex: 1, originalCount: 0)
        XCTAssertTrue(neighbor.isActiveOrNeighbor)

        let distant = CarouselState(activeIndex: 2, pageIndex: 4, originalCount: 0)
        XCTAssertFalse(distant.isActiveOrNeighbor)
    }

    // MARK: - Equatable Tests

    func testEquatable() {
        let state1 = CarouselState(activeIndex: 1, pageIndex: 2, originalCount: 5)
        let state2 = CarouselState(activeIndex: 1, pageIndex: 2, originalCount: 5)
        let state3 = CarouselState(activeIndex: 1, pageIndex: 3, originalCount: 5)

        XCTAssertEqual(state1, state2)
        XCTAssertNotEqual(state1, state3)
    }

}

#endif
