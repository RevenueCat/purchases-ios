//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FixtureRootView.swift
//
//  Created by Facundo Menzella on 8/5/26.

import SwiftUI
@_spi(Internal) import RevenueCat
@_spi(Internal) import RevenueCatUI

struct FixtureRootView: View {

    let requestedFixture: String?

    var body: some View {
        if let requestedFixture {
            if let fixture = PaywallFixture(rawValue: requestedFixture) {
                FixturePaywallView(fixture: fixture)
            } else {
                // Named as text so a failing test reports the bad name instead of timing out.
                Text("Unknown fixture: \(requestedFixture)")
            }
        } else {
            NavigationView {
                List(PaywallFixture.allCases, id: \.self) { fixture in
                    NavigationLink(fixture.title) {
                        FixturePaywallView(fixture: fixture)
                    }
                }
                .navigationTitle("Fixtures")
            }
        }
    }

}

struct FixturePaywallView: View {

    let fixture: PaywallFixture

    /// Eligibility is stubbed, customer info is supplied rather than fetched, and purchases are
    /// no-ops, so nothing here reaches StoreKit or the network and the accessibility tree depends
    /// only on the fixture.
    private static let eligibility = TrialOrIntroEligibilityChecker { packages in
        Dictionary(uniqueKeysWithValues: packages.map { ($0, IntroEligibilityStatus.eligible) })
    }

    private static let customerInfo = CustomerInfo(
        entitlements: .init(),
        requestDate: Date(timeIntervalSince1970: 0),
        firstSeen: Date(timeIntervalSince1970: 0),
        originalAppUserId: "fixtures"
    )

    var body: some View {
        PaywallView(
            offering: self.fixture.offering,
            customerInfo: Self.customerInfo,
            introEligibility: Self.eligibility,
            performPurchase: { _ in (userCancelled: true, error: nil) },
            performRestore: { (success: false, error: nil) }
        )
    }

}
