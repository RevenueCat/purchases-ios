//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CarouselPagingTests.swift

@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

class CarouselPagingTests: TestCase {

    private static let pageWidth: CGFloat = 100
    private static let fast: CGFloat = 1000
    private static let slow: CGFloat = 100

    // MARK: - Fling

    func testShortFastFlickForwardAdvances() {
        XCTAssertEqual(Self.target(start: 1, drag: -0.1, velocity: -Self.fast), 2)
    }

    func testShortFastFlickBackwardGoesBack() {
        XCTAssertEqual(Self.target(start: 1, drag: 0.1, velocity: Self.fast), 0)
    }

    func testReverseFlickReturnsToStartPage() {
        XCTAssertEqual(Self.target(start: 1, drag: -0.3, velocity: Self.fast), 1)
    }

    func testFlickWithoutDragMovesToAdjacentPageInVelocityDirection() {
        XCTAssertEqual(Self.target(start: 1, drag: 0, velocity: -Self.fast), 2)
        XCTAssertEqual(Self.target(start: 1, drag: 0, velocity: Self.fast), 0)
    }

    func testMinFlingVelocityIsInclusive() {
        XCTAssertEqual(Self.target(start: 1, drag: -0.1, velocity: -CarouselPaging.minFlingVelocity), 2)
        XCTAssertEqual(Self.target(start: 1, drag: -0.1, velocity: -CarouselPaging.minFlingVelocity + 1), 1)
    }

    func testFlingMovesAtMostOnePage() {
        XCTAssertEqual(Self.target(start: 1, drag: -1.5, velocity: -Self.fast, count: 5), 2)
    }

    // MARK: - Slow drag

    func testSlowShortDragSnapsBack() {
        XCTAssertEqual(Self.target(start: 1, drag: -0.3, velocity: -Self.slow), 1)
    }

    func testSlowDragPastHalfAdvances() {
        XCTAssertEqual(Self.target(start: 1, drag: -0.6, velocity: -Self.slow), 2)
        XCTAssertEqual(Self.target(start: 1, drag: 0.6, velocity: Self.slow), 0)
    }

    func testSlowDragOfExactlyHalfSnapsBack() {
        XCTAssertEqual(Self.target(start: 1, drag: -0.5, velocity: 0), 1)
    }

    func testSlowDragMovesAtMostOnePage() {
        XCTAssertEqual(Self.target(start: 1, drag: -1.5, velocity: 0, count: 5), 2)
    }

    // MARK: - Bounds

    func testNonLoopClampsAtFirstPage() {
        XCTAssertEqual(Self.target(start: 0, drag: 0.3, velocity: Self.fast, loop: false), 0)
    }

    func testLoopReturnsIndexBeforeFirstPage() {
        XCTAssertEqual(Self.target(start: 0, drag: 0.3, velocity: Self.fast, loop: true), -1)
    }

    func testNonLoopClampsAtLastPage() {
        XCTAssertEqual(Self.target(start: 2, drag: -0.3, velocity: -Self.fast, count: 3, loop: false), 2)
    }

    func testZeroPageWidthStays() {
        XCTAssertEqual(
            CarouselPaging.targetIndex(
                start: 1,
                dragOffset: -50,
                velocity: -Self.fast,
                pageWidth: 0,
                count: 3,
                loop: false
            ),
            1
        )
    }

    // MARK: - Velocity tracker

    func testTrackerMeasuresVelocityInPointsPerSecond() {
        let start = Date()
        var tracker = CarouselDragVelocityTracker()
        for step in 0...20 {
            tracker.addSample(translation: -CGFloat(step) * 10, at: start.addingTimeInterval(Double(step) * 0.01))
        }

        XCTAssertEqual(tracker.velocity(endingAt: start.addingTimeInterval(0.21)), -1000, accuracy: 1)
    }

    func testTrackerReportsFullSpeedFromASingleInterval() {
        let start = Date()
        var tracker = CarouselDragVelocityTracker()
        tracker.addSample(translation: 0, at: start)
        tracker.addSample(translation: -6, at: start.addingTimeInterval(0.01))

        XCTAssertEqual(tracker.velocity(endingAt: start.addingTimeInterval(0.01)), -600, accuracy: 1)
    }

    func testTrackerReportsZeroAfterStall() {
        let start = Date()
        var tracker = CarouselDragVelocityTracker()
        tracker.addSample(translation: 0, at: start)
        tracker.addSample(translation: -20, at: start.addingTimeInterval(0.01))

        XCTAssertEqual(tracker.velocity(endingAt: start.addingTimeInterval(0.2)), 0)
    }

    // MARK: - Helpers

    /// `drag` is a fraction of the page width.
    private static func target(
        start: Int,
        drag: CGFloat,
        velocity: CGFloat,
        count: Int = 3,
        loop: Bool = false
    ) -> Int {
        return CarouselPaging.targetIndex(
            start: start,
            dragOffset: drag * Self.pageWidth,
            velocity: velocity,
            pageWidth: Self.pageWidth,
            count: count,
            loop: loop
        )
    }

}

#endif
