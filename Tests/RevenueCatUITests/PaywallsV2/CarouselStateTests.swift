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

    // MARK: - Distance From Active

    func testDistanceFromActiveUsesAbsoluteDataIndexDifference() {
        XCTAssertEqual(CarouselState(
            activeIndex: 2,
            pageIndex: 2,
            ancestorDistanceFromActive: 0
        ).distanceFromActive, 0)
        XCTAssertEqual(CarouselState(
            activeIndex: 2,
            pageIndex: 0,
            ancestorDistanceFromActive: 0
        ).distanceFromActive, 2)
        XCTAssertEqual(CarouselState(
            activeIndex: 2,
            pageIndex: 4,
            ancestorDistanceFromActive: 0
        ).distanceFromActive, 2)
    }

    func testDistanceFromActiveIncludesEnclosingCarouselDistance() {
        let state = CarouselState(
            activeIndex: 0,
            pageIndex: 0,
            ancestorDistanceFromActive: 3
        )

        XCTAssertEqual(state.distanceFromActive, 3)
        XCTAssertFalse(state.isActiveOrNeighbor)
    }

    // MARK: - isActiveOrNeighbor Tests

    func testIsActiveOrNeighborReturnsTrueForActiveIndex() {
        let state = CarouselState(activeIndex: 2, pageIndex: 2, ancestorDistanceFromActive: 0)
        XCTAssertTrue(state.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborReturnsTrueForPreviousPage() {
        let state = CarouselState(activeIndex: 2, pageIndex: 1, ancestorDistanceFromActive: 0)
        XCTAssertTrue(state.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborReturnsTrueForNextPage() {
        let state = CarouselState(activeIndex: 2, pageIndex: 3, ancestorDistanceFromActive: 0)
        XCTAssertTrue(state.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborReturnsFalseForDistantPage() {
        let state = CarouselState(activeIndex: 2, pageIndex: 4, ancestorDistanceFromActive: 0)
        XCTAssertFalse(state.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborUsesDataIndicesInExpandedCarousel() {
        // In a looping carousel, indices are from the expanded data array.
        // User starts in the middle copy (index 5 for a 5-page carousel).
        let active = CarouselState(activeIndex: 5, pageIndex: 5, ancestorDistanceFromActive: 0)
        let neighbor = CarouselState(activeIndex: 5, pageIndex: 6, ancestorDistanceFromActive: 0)
        let distant = CarouselState(activeIndex: 5, pageIndex: 10, ancestorDistanceFromActive: 0)

        XCTAssertTrue(active.isActiveOrNeighbor)
        XCTAssertTrue(neighbor.isActiveOrNeighbor)
        XCTAssertFalse(distant.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborWithSinglePageCarousel() {
        let state = CarouselState(activeIndex: 0, pageIndex: 0, ancestorDistanceFromActive: 0)
        XCTAssertTrue(state.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborWithTwoPageCarousel() {
        // Both pages are always neighbors in a 2-page carousel
        let state1 = CarouselState(activeIndex: 0, pageIndex: 1, ancestorDistanceFromActive: 0)
        XCTAssertTrue(state1.isActiveOrNeighbor)

        let state2 = CarouselState(activeIndex: 1, pageIndex: 0, ancestorDistanceFromActive: 0)
        XCTAssertTrue(state2.isActiveOrNeighbor)
    }

    func testIsActiveOrNeighborWithThreePageCarouselUsesDataAdjacency() {
        let active = CarouselState(activeIndex: 0, pageIndex: 0, ancestorDistanceFromActive: 0)
        let neighbor = CarouselState(activeIndex: 0, pageIndex: 1, ancestorDistanceFromActive: 0)
        let distant = CarouselState(activeIndex: 0, pageIndex: 2, ancestorDistanceFromActive: 0)

        XCTAssertTrue(active.isActiveOrNeighbor)
        XCTAssertTrue(neighbor.isActiveOrNeighbor)
        XCTAssertFalse(distant.isActiveOrNeighbor)
    }

    // MARK: - Equatable Tests

    func testEquatable() {
        let state1 = CarouselState(activeIndex: 1, pageIndex: 2, ancestorDistanceFromActive: 0)
        let state2 = CarouselState(activeIndex: 1, pageIndex: 2, ancestorDistanceFromActive: 0)
        let state3 = CarouselState(activeIndex: 1, pageIndex: 3, ancestorDistanceFromActive: 0)

        XCTAssertEqual(state1, state2)
        XCTAssertNotEqual(state1, state3)
    }

}

#endif
