//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OnWebCheckoutOpenedModifierTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

/// Verifies the `.onWebCheckoutOpened` modifier's `PreferenceKey` plumbing.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class OnWebCheckoutOpenedModifierTests: TestCase {

    func testOnWebCheckoutOpenedFiresForEachSignal() {
        let handler: PurchaseHandler = .mock()
        let fireCount: Atomic<Int> = .init(0)

        let view = ProbeView(handler: handler) {
            fireCount.modify { $0 += 1 }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        expect(fireCount.value) == 0

        // Mutating the handler directly isolates the preference/modifier plumbing from gesture handling.
        handler.signalWebCheckoutOpened()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(fireCount.value) == 1

        // Must fire again, not be deduped as an identical value.
        handler.signalWebCheckoutOpened()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(fireCount.value) == 2
    }

    func testOnWebCheckoutOpenedFiresEvenWhenResetImmediatelyAfter() {
        let handler: PurchaseHandler = .mock()
        let fireCount: Atomic<Int> = .init(0)

        let view = ProbeView(handler: handler) {
            fireCount.modify { $0 += 1 }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        expect(fireCount.value) == 0

        // Mirrors handleMainPaywallDismiss: signal then immediately reset, no RunLoop spin in between.
        handler.signalWebCheckoutOpened()
        handler.resetForNewSession()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        expect(fireCount.value) == 1
    }

    func testOnWebCheckoutOpenedDoesNotFireOnNewViewAfterExitOfferClear() {
        // clearWebCheckoutOpened() must complete synchronously so a new view reusing this handler
        // (the exit offer) doesn't see the stale signal as its own fresh one.
        let handler: PurchaseHandler = .mock()
        handler.signalWebCheckoutOpened()
        handler.clearWebCheckoutOpened()

        let fireCount: Atomic<Int> = .init(0)
        let view = ProbeView(handler: handler) {
            fireCount.modify { $0 += 1 }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(fireCount.value) == 0
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ProbeView: View {

    @ObservedObject var handler: PurchaseHandler
    let onWebCheckoutOpened: WebCheckoutOpenedHandler

    var body: some View {
        Color.clear
            .preference(key: WebCheckoutOpenedPreferenceKey.self, value: self.handler.webCheckoutOpened)
            .onWebCheckoutOpened(self.onWebCheckoutOpened)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension OnWebCheckoutOpenedModifierTests {

    static func host<Content: View>(_ view: Content) -> (UIWindow, UIView) {
        let controller = UIHostingController(rootView: view.frame(width: 100, height: 100))
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return (window, controller.view)
    }

}

#endif
