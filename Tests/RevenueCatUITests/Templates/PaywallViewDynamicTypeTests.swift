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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallViewDynamicTypeTests {

    static func test(_ type: DynamicTypeSize) {
        Self.createView(type)
            .snapshot(size: Self.fullScreenSize)
    }

    private static func createView(_ type: DynamicTypeSize) -> some View {
        return Self.createPaywall(
            offering: TestData
                .offeringWithIntroOffer
                .withLocalImages
        )
            .dynamicTypeSize(type)
    }

}
