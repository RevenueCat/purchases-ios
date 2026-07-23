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

/// Verifies the `.onWebCheckoutOpened` modifier's `PreferenceKey` plumbing: that a
/// `PurchaseHandler.signalWebCheckoutOpened()` call is propagated all the way to the handler
/// closure, and that consecutive signals each fire it (not deduped as a single change).
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

        // Mutate the handler directly rather than simulating a button tap: this isolates the
        // preference/modifier plumbing from gesture handling, matching the approach already used
        // for other SwiftUI state propagation regressions (see TabsComponentDuplicateInstanceTests).
        handler.signalWebCheckoutOpened()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(fireCount.value) == 1

        // A second, distinct tap must fire again rather than being treated as an identical value.
        handler.signalWebCheckoutOpened()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(fireCount.value) == 2
    }

    func testOnWebCheckoutOpenedFiresEvenWhenClearedImmediatelyAfter() {
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

        // Mirrors openWebPaywallLink: signaling then immediately clearing/resetting in the same
        // synchronous step, with no RunLoop spin in between. If the clear weren't deferred, this would
        // coalesce away the SwiftUI render pass that delivers the signal, silently dropping the callback.
        handler.signalWebCheckoutOpened()
        handler.clearWebCheckoutOpened()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        expect(fireCount.value) == 1
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
