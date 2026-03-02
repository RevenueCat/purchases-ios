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
        // In a looping carousel, isActive represents the visible data index only.
        let state = CarouselState(activeIndex: 3, pageIndex: 0, originalCount: 3)
        XCTAssertFalse(state.isActive, "Only the active data index should be marked active")
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

    func testIsActiveOrNeighborUsesDataIndicesInExpandedCarousel() {
        // In a looping carousel, indices are from the expanded data array.
        // User starts in the middle copy (index 5 for a 5-page carousel).
        let active = CarouselState(activeIndex: 5, pageIndex: 5, originalCount: 5)
        let neighbor = CarouselState(activeIndex: 5, pageIndex: 6, originalCount: 5)
        let distant = CarouselState(activeIndex: 5, pageIndex: 10, originalCount: 5)

        XCTAssertTrue(active.isActiveOrNeighbor)
        XCTAssertTrue(neighbor.isActiveOrNeighbor)
        XCTAssertFalse(distant.isActiveOrNeighbor)
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

    func testIsActiveOrNeighborWithThreePageCarouselUsesDataAdjacency() {
        let active = CarouselState(activeIndex: 0, pageIndex: 0, originalCount: 3)
        let neighbor = CarouselState(activeIndex: 0, pageIndex: 1, originalCount: 3)
        let distant = CarouselState(activeIndex: 0, pageIndex: 2, originalCount: 3)

        XCTAssertTrue(active.isActiveOrNeighbor)
        XCTAssertTrue(neighbor.isActiveOrNeighbor)
        XCTAssertFalse(distant.isActiveOrNeighbor)
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
