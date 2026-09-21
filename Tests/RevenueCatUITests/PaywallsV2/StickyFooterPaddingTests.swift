//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StickyFooterPaddingTests.swift
//
//  Created by Michael S. Muegel on 8/29/26.

import Nimble
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class StickyFooterPaddingTests: TestCase {

    func testPadsAnIPadWithNoBottomSafeArea() {
        expect(RootView.stickyFooterBottomPadding(safeAreaBottom: 0, idiom: .pad)).to(equal(16))
    }

    func testLeavesAPhoneWithABottomSafeAreaUnchanged() {
        expect(RootView.stickyFooterBottomPadding(safeAreaBottom: 34, idiom: .phone)).to(equal(34))
    }

    func testKeepsALargerSafeAreaOverTheDefault() {
        expect(RootView.stickyFooterBottomPadding(safeAreaBottom: 20, idiom: .pad)).to(equal(20))
    }

    func testPadsAMacWindowWithNoBottomSafeArea() {
        expect(RootView.stickyFooterBottomPadding(safeAreaBottom: 0, idiom: .mac)).to(equal(16))
    }

    func testPadsAVisionOSWindowWithNoBottomSafeArea() {
        expect(RootView.stickyFooterBottomPadding(safeAreaBottom: 0, idiom: .vision)).to(equal(16))
    }

    func testLeavesOtherIdiomsAlone() {
        expect(RootView.stickyFooterBottomPadding(safeAreaBottom: 0, idiom: .phone)).to(equal(0))
        expect(RootView.stickyFooterBottomPadding(safeAreaBottom: 0, idiom: .watch)).to(equal(0))
        expect(RootView.stickyFooterBottomPadding(safeAreaBottom: 0, idiom: .unknown)).to(equal(0))
    }

}

#endif
