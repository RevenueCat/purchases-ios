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
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

/// Exercises the production event bridge and public callback modifier in a hosted SwiftUI view.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class OnWebCheckoutOpenedModifierTests: TestCase {

    func testOnWebCheckoutOpenedFiresEvenWhenResetImmediatelyAfter() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<Int> = .init(0)
        let window = Self.host(Self.probe(handler).onWebCheckoutOpened({ received.modify { $0 += 1 } }))
        defer { Self.unhost(window) }

        handler.signalWebCheckoutOpened()
        handler.resetForNewSession()

        expect(received.value) == 1
    }

    func testRepeatedEventsWithoutRendering() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<Int> = .init(0)
        let window = Self.host(Self.probe(handler).onWebCheckoutOpened({ received.modify { $0 += 1 } }))
        defer { Self.unhost(window) }

        handler.signalWebCheckoutOpened()
        handler.signalWebCheckoutOpened()

        expect(received.value) == 2
    }

    func testNewSessionImmediatelySignalsAgain() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<Int> = .init(0)
        let window = Self.host(Self.probe(handler).onWebCheckoutOpened({ received.modify { $0 += 1 } }))
        defer { Self.unhost(window) }

        handler.signalWebCheckoutOpened()
        handler.resetForNewSession()
        handler.signalWebCheckoutOpened()

        expect(received.value) == 2
    }

    func testNewPresentationDoesNotReplayAndReceivesNewEvents() {
        let handler: PurchaseHandler = .mock()
        let oldReceived: Atomic<Int> = .init(0)
        let oldWindow = Self.host(Self.probe(handler).onWebCheckoutOpened({ oldReceived.modify { $0 += 1 } }))
        handler.signalWebCheckoutOpened()
        expect(oldReceived.value) == 1
        Self.unhost(oldWindow)
        handler.resetForNewSession()

        let received: Atomic<Int> = .init(0)
        let window = Self.host(Self.probe(handler).onWebCheckoutOpened({ received.modify { $0 += 1 } }))
        defer { Self.unhost(window) }
        expect(received.value) == 0
        handler.signalWebCheckoutOpened()
        expect(received.value) == 1
        expect(oldReceived.value) == 1
    }

    func testUnmountedViewDoesNotReceiveEventsWhileControllerIsRetained() throws {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<Int> = .init(0)
        let disappeared: Atomic<Bool> = .init(false)
        let view = Self.probe(handler)
            .onWebCheckoutOpened({ received.modify { $0 += 1 } })
            .onDisappear { disappeared.value = true }
        let window = Self.host(view)
        defer { Self.unhost(window) }
        let controller = try XCTUnwrap(window.rootViewController)

        handler.signalWebCheckoutOpened()
        expect(received.value) == 1
        Self.unhost(window)
        expect(disappeared.value) == true

        handler.resetForNewSession()
        handler.signalWebCheckoutOpened()
        expect(received.value) == 1
        withExtendedLifetime(controller) {}
    }

    func testEventBeforeMountDoesNotReplayWithoutReset() {
        let handler: PurchaseHandler = .mock()
        handler.signalWebCheckoutOpened()
        let received: Atomic<Int> = .init(0)
        let window = Self.host(Self.probe(handler).onWebCheckoutOpened({ received.modify { $0 += 1 } }))
        defer { Self.unhost(window) }
        expect(received.value) == 0
    }

    func testNestedBridgesAndRetainedPagesDeliverOnce() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<Int> = .init(0)
        let view = VStack {
            Self.probe(handler)
            Self.probe(handler)
        }
        .modifier(PaywallURLEventsModifier(purchaseHandler: handler))
        .onWebCheckoutOpened({ received.modify { $0 += 1 } })
        let window = Self.host(view)
        defer { Self.unhost(window) }

        handler.signalWebCheckoutOpened()
        expect(received.value) == 1
    }

    func testNestedCallbackModifiersEachReceiveEvent() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<Int> = .init(0)
        let view = VStack {
            Self.probe(handler).onWebCheckoutOpened({ received.modify { $0 += 1 } })
        }
        .onWebCheckoutOpened({ received.modify { $0 += 1 } })
        let window = Self.host(view)
        defer { Self.unhost(window) }

        handler.signalWebCheckoutOpened()
        expect(received.value) == 2
    }

    func testCallbackCanResetSession() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<Int> = .init(0)
        let view = Self.probe(handler).onWebCheckoutOpened {
            handler.resetForNewSession()
            received.modify { $0 += 1 }
        }
        let window = Self.host(view)
        defer { Self.unhost(window) }

        handler.signalWebCheckoutOpened()
        expect(received.value) == 1
    }

    func testOtherEventDoesNotInvokeCallback() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<Int> = .init(0)
        let window = Self.host(Self.probe(handler).onWebCheckoutOpened({ received.modify { $0 += 1 } }))
        defer { Self.unhost(window) }

        handler.signalURLOpened(URL(string: "https://revenuecat.com/terms")!)
        expect(received.value) == 0
    }

    func testPaywallViewDeliversEventBeforeImmediateReset() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<Int> = .init(0)
        let view = PaywallView(configuration: .init(
            offering: TestData.offeringWithIntroOffer,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: handler
        ))
        .onWebCheckoutOpened {
            received.modify { $0 += 1 }
        }
        let window = Self.host(view)
        defer { Self.unhost(window) }

        handler.signalWebCheckoutOpened()
        handler.resetForNewSession()
        expect(received.value) == 1
    }

    private static func probe(_ handler: PurchaseHandler) -> some View {
        Color.clear.modifier(PaywallURLEventsModifier(purchaseHandler: handler))
    }

    private static func host<Content: View>(_ view: Content) -> UIWindow {
        let controller = UIHostingController(rootView: AnyView(view.frame(width: 100, height: 100)))
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return window
    }

    private static func unhost(_ window: UIWindow) {
        // Hiding a test window alone does not trigger onDisappear on older iOS.
        if let controller = window.rootViewController as? UIHostingController<AnyView> {
            controller.rootView = AnyView(EmptyView())
            controller.view.layoutIfNeeded()
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        window.isHidden = true
        window.rootViewController = nil
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }

}

#endif
