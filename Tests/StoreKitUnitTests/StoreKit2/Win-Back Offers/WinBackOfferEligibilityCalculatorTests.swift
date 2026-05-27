//
//  WinBackOfferEligibilityCalculatorTests.swift
//  StoreKitUnitTests
//
//  Created by Will Taylor on 5/27/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
class WinBackOfferEligibilityCalculatorTests: StoreKitConfigTestCase {
    func test() async throws {
        let monthlyProduct = try await fetchSk2Product("com.revenuecat.monthly_4.99.1_week_intro")
        print(monthlyProduct.id)
    }
}
