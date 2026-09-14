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

/// The drag path and the screen-reader path share this, so a difference between them would show
/// up as a carousel that pages differently depending on how you drive it.
final class CarouselPagingTests: TestCase {

    func testMovesByTheDelta() {
        XCTAssertEqual(CarouselPaging.index(from: 2, by: 1, count: 5, loop: false), 3)
        XCTAssertEqual(CarouselPaging.index(from: 2, by: -1, count: 5, loop: false), 1)
        XCTAssertEqual(CarouselPaging.index(from: 2, by: 0, count: 5, loop: false), 2)
    }

    func testClampsAtTheEndsWhenNotLooping() {
        XCTAssertEqual(CarouselPaging.index(from: 4, by: 1, count: 5, loop: false), 4)
        XCTAssertEqual(CarouselPaging.index(from: 0, by: -1, count: 5, loop: false), 0)
    }

    /// A looping carousel grows its data as it goes, so clamping here would fight that.
    func testDoesNotClampWhenLooping() {
        XCTAssertEqual(CarouselPaging.index(from: 4, by: 1, count: 5, loop: true), 5)
        XCTAssertEqual(CarouselPaging.index(from: 0, by: -1, count: 5, loop: true), -1)
    }

    func testEmptyDataStaysPut() {
        XCTAssertEqual(CarouselPaging.index(from: 0, by: 1, count: 0, loop: false), 0)
    }

}

#endif
