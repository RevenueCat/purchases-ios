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
            if requestedFixture == AccessibilityControlView.fixtureName {
                AccessibilityControlView()
            } else if let fixture = PaywallFixture(rawValue: requestedFixture) {
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

/// Plain SwiftUI images with no RevenueCat code involved, so a test can establish what
/// `accessibilityHidden` is expected to do in this harness before asserting the same thing
/// about paywall media. Without this control, a paywall image showing up in the tree cannot be
/// told apart from the test runner simply not honoring the modifier.
struct AccessibilityControlView: View {

    static let fixtureName = "a11y_control"

    var body: some View {
        VStack(spacing: 20) {
            Text("Control")

            Image(systemName: "star.fill")
                .resizable()
                .frame(width: 40, height: 40)

            Image(systemName: "heart.fill")
                .resizable()
                .frame(width: 41, height: 41)
                .accessibilityHidden(true)

            // The paywall's own pattern: hidden after being collapsed into one element.
            Image(systemName: "bolt.fill")
                .resizable()
                .frame(width: 42, height: 42)
                .accessibilityElement(children: .ignore)
                .accessibilityHidden(true)
        }
    }

}

struct FixturePaywallView: View {

    let fixture: PaywallFixture

    /// Eligibility is stubbed and purchases are no-ops, so nothing here reaches StoreKit or the
    /// network and the accessibility tree depends only on the fixture.
    private static let eligibility = TrialOrIntroEligibilityChecker { packages in
        Dictionary(uniqueKeysWithValues: packages.map { ($0, IntroEligibilityStatus.eligible) })
    }

    /// Env-var driven so a UI test controls the modifiers per launch. Only applied when
    /// requested: `paywallImagesAccessibilityHidden(false)` is an explicit opt-in to
    /// announcements, not the default, so unconditional application would change behavior.
    private var hidesImages: Bool {
        ProcessInfo.processInfo.environment["PAYWALL_HIDE_IMAGES"] == "1"
    }

    private var hidesIcons: Bool {
        ProcessInfo.processInfo.environment["PAYWALL_HIDE_ICONS"] == "1"
    }

    var body: some View {
        let paywall = PaywallView(
            offering: self.fixture.offering,
            introEligibility: Self.eligibility,
            performPurchase: { _ in (userCancelled: true, error: nil) },
            performRestore: { (success: false, error: nil) }
        )
        .paywallIconsAccessibilityHidden(self.hidesIcons)

        if self.hidesImages {
            paywall.paywallImagesAccessibilityHidden()
        } else {
            paywall
        }
    }

}
