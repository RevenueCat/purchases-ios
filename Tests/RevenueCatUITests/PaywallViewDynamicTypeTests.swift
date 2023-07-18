//
//  PaywallViewDynamicTypeTests.swift
//  
//
//  Created by Nacho Soto on 7/17/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class PaywallViewDynamicTypeTests: BaseSnapshotTest {

    func testXSmall() {
        Self.test(.xSmall)
    }

    func testSmall() {
        Self.test(.small)
    }

    func testMedium() {
        Self.test(.medium)
    }

    func testLarge() {
        Self.test(.xLarge)
    }

    func testXLarge() {
        Self.test(.xLarge)
    }

    func testXXLarge() {
        Self.test(.xxLarge)
    }

    func testXXXLarge() {
        Self.test(.xxxLarge)
    }

    func testAccessibility1() {
        Self.test(.accessibility1)
    }

    func testAccessibility3() {
        Self.test(.accessibility3)
    }

    func testAccessibility5() {
        Self.test(.accessibility5)
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private extension PaywallViewDynamicTypeTests {

    static func test(_ type: DynamicTypeSize) {
        Self.createView(type)
            .snapshot(size: Self.fullScreenSize)
    }

    private static func createView(_ type: DynamicTypeSize) -> some View {
        let offering = TestData.offeringWithIntroOffer

        return PaywallView(offering: offering,
                           paywall: offering.paywallWithLocalImage,
                           introEligibility: Self.eligibleChecker,
                           purchaseHandler: Self.purchaseHandler)
            .dynamicTypeSize(type)
    }

}
