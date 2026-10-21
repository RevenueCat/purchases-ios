//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseDetailViewModelTests.swift
//
//  Created by Will Taylor on 10/20/2026.

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if os(iOS)

@available(iOS 15.0, *)
final class PurchaseDetailViewModelTests: TestCase {

    func testLocalizedOwnershipForPurchased() {
        expect(Self.viewModel(ownershipType: .purchased).localizedOwnership).to(beNil())
    }

    func testLocalizedOwnershipForFamilyShared() {
        expect(Self.viewModel(ownershipType: .familyShared).localizedOwnership) == .sharedThroughFamilyMember
    }

    func testLocalizedOwnershipForAssigned() {
        expect(Self.viewModel(ownershipType: .assigned).localizedOwnership) == .assignedThroughOrganization
    }

    func testLocalizedOwnershipForUnknown() {
        expect(Self.viewModel(ownershipType: .unknown).localizedOwnership).to(beNil())
    }

}

@available(iOS 15.0, *)
private extension PurchaseDetailViewModelTests {

    static func viewModel(ownershipType: PurchaseOwnershipType) -> PurchaseDetailViewModel {
        PurchaseDetailViewModel(purchaseInfo: .mock(ownershipType: ownershipType))
    }

}

#endif
