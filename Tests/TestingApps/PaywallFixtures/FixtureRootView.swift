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
            if requestedFixture == AccessibilityHiddenControlView.fixtureName {
                AccessibilityHiddenControlView()
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

struct AccessibilityHiddenControlView: View {

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

    /// XCUITest cannot turn VoiceOver on, so a test says so through the override instead.
    /// Stays `nil` otherwise, or it would answer for the real thing and force it off on device.
    private var pretendsVoiceOverIsRunning: Bool? {
        ProcessInfo.processInfo.environment["PAYWALL_VOICE_OVER"] == "1" ? true : nil
    }

    /// Opts in the way an app does at the root of its own presentation. Left unset otherwise, so
    /// the paywall keeps the default a directly presented `PaywallView` gets.
    private var movesCloseButtonToSideToolbar: Bool {
        ProcessInfo.processInfo.environment["PAYWALL_SIDE_TOOLBAR_CLOSE"] == "1"
    }

    var body: some View {
        Group {
            if self.movesCloseButtonToSideToolbar {
                self.paywall
                    .movePaywallCancelButtonToSideToolbarWhenAppropriate()
            } else {
                self.paywall
            }
        }
        .overlay(alignment: .topLeading) {
            VerticalToolbarSupportMarkerView()
        }
    }

    private var paywall: some View {
        PaywallView(
            offering: self.fixture.offering,
            introEligibility: Self.eligibility,
            simulatePromoEligible: true,
            performPurchase: { _ in (userCancelled: true, error: nil) },
            performRestore: { (success: false, error: nil) }
        )
        .environment(\.voiceOverEnabledOverride, self.pretendsVoiceOverIsRunning)
    }

}

/// Reports whether the window supports a vertical toolbar, so a UI test can tell a presentation
/// where the close button should move from one where it should stay.
struct VerticalToolbarSupportMarkerView: View {

    static let identifier = "vertical_toolbar_support"

    var body: some View {
        // Vertical toolbars need the iOS 27.1 SDK, which ships the same Swift compiler as 27.0.
        #if os(iOS) && canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, *), VerticalToolbarEdgeMarkerView.isSupported {
            VerticalToolbarEdgeMarkerView()
        } else {
            Self.marker(isSupported: false)
        }
        #else
        Self.marker(isSupported: false)
        #endif
    }

    static func marker(isSupported: Bool) -> some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(isSupported ? "supported" : "unsupported")
            .accessibilityIdentifier(Self.identifier)
    }

}

#if os(iOS) && canImport(SwiftUI, _version: 8.0.85)
@available(iOS 27.1, *)
private struct VerticalToolbarEdgeMarkerView: View {

    /// SDK releases made in parallel with iOS 27.1 can lack the vertical toolbar declarations.
    static var isSupported: Bool {
        if #_hasSymbol(EnvironmentValues().toolbarVerticalEdge) {
            return true
        }
        return false
    }

    @Environment(\.toolbarVerticalEdge)
    private var toolbarVerticalEdge

    var body: some View {
        VerticalToolbarSupportMarkerView.marker(isSupported: self.toolbarVerticalEdge != nil)
    }

}
#endif
