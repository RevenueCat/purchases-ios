//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OnURLOpenedModifierTests.swift
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
final class OnURLOpenedModifierTests: TestCase {

    private static let url = URL(string: "https://revenuecat.com/terms")!

    func testOnURLOpenedFiresEvenWhenResetImmediatelyAfter() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<[URL]> = .init([])
        let window = Self.host(Self.probe(handler).onURLOpened({ url in received.modify { $0.append(url) } }))
        defer { Self.unhost(window) }

        handler.signalURLOpened(Self.url)
        handler.resetForNewSession()

        expect(received.value) == [Self.url]
    }

    func testRepeatedEventsWithoutRendering() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<[URL]> = .init([])
        let window = Self.host(Self.probe(handler).onURLOpened({ url in received.modify { $0.append(url) } }))
        defer { Self.unhost(window) }

        handler.signalURLOpened(Self.url)
        handler.signalURLOpened(Self.url)

        expect(received.value) == [Self.url, Self.url]
    }

    func testNewSessionImmediatelySignalsAgain() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<[URL]> = .init([])
        let window = Self.host(Self.probe(handler).onURLOpened({ url in received.modify { $0.append(url) } }))
        defer { Self.unhost(window) }

        handler.signalURLOpened(Self.url)
        handler.resetForNewSession()
        handler.signalURLOpened(Self.url)

        expect(received.value) == [Self.url, Self.url]
    }

    func testNewPresentationDoesNotReplayAndReceivesNewEvents() {
        let handler: PurchaseHandler = .mock()
        let oldReceived: Atomic<[URL]> = .init([])
        let oldWindow = Self.host(Self.probe(handler).onURLOpened({ url in oldReceived.modify { $0.append(url) } }))
        handler.signalURLOpened(Self.url)
        expect(oldReceived.value) == [Self.url]
        Self.unhost(oldWindow)
        handler.resetForNewSession()

        let received: Atomic<[URL]> = .init([])
        let window = Self.host(Self.probe(handler).onURLOpened({ url in received.modify { $0.append(url) } }))
        defer { Self.unhost(window) }
        expect(received.value) == []
        handler.signalURLOpened(Self.url)
        expect(received.value) == [Self.url]
        expect(oldReceived.value) == [Self.url]
    }

    func testEventBeforeMountDoesNotReplayWithoutReset() {
        let handler: PurchaseHandler = .mock()
        handler.signalURLOpened(Self.url)
        let received: Atomic<[URL]> = .init([])
        let window = Self.host(Self.probe(handler).onURLOpened({ url in received.modify { $0.append(url) } }))
        defer { Self.unhost(window) }
        expect(received.value) == []
    }

    func testNestedBridgesAndRetainedPagesDeliverOnce() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<[URL]> = .init([])
        let view = VStack {
            Self.probe(handler)
            Self.probe(handler)
        }
        .modifier(PaywallURLEventsModifier(purchaseHandler: handler))
        .onURLOpened({ url in received.modify { $0.append(url) } })
        let window = Self.host(view)
        defer { Self.unhost(window) }

        handler.signalURLOpened(Self.url)
        expect(received.value) == [Self.url]
    }

    func testNestedCallbackModifiersEachReceiveEvent() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<[URL]> = .init([])
        let view = VStack {
            Self.probe(handler).onURLOpened({ url in received.modify { $0.append(url) } })
        }
        .onURLOpened({ url in received.modify { $0.append(url) } })
        let window = Self.host(view)
        defer { Self.unhost(window) }

        handler.signalURLOpened(Self.url)
        expect(received.value) == [Self.url, Self.url]
    }

    func testCallbackCanResetSession() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<[URL]> = .init([])
        let view = Self.probe(handler).onURLOpened { url in
            handler.resetForNewSession()
            received.modify { $0.append(url) }
        }
        let window = Self.host(view)
        defer { Self.unhost(window) }

        handler.signalURLOpened(Self.url)
        expect(received.value) == [Self.url]
    }

    func testOtherEventDoesNotInvokeCallback() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<[URL]> = .init([])
        let window = Self.host(Self.probe(handler).onURLOpened({ url in received.modify { $0.append(url) } }))
        defer { Self.unhost(window) }

        handler.signalWebCheckoutOpened()
        expect(received.value) == []
    }

    func testPaywallViewDeliversEventBeforeImmediateReset() {
        let handler: PurchaseHandler = .mock()
        let received: Atomic<Int> = .init(0)
        let view = PaywallView(configuration: .init(
            offering: TestData.offeringWithIntroOffer,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: handler
        ))
        .onURLOpened { _ in
            received.modify { $0 += 1 }
        }
        let window = Self.host(view)
        defer { Self.unhost(window) }

        handler.signalURLOpened(Self.url)
        handler.resetForNewSession()
        expect(received.value) == 1
    }

    private static func probe(_ handler: PurchaseHandler) -> some View {
        Color.clear.modifier(PaywallURLEventsModifier(purchaseHandler: handler))
    }

    private static func host<Content: View>(_ view: Content) -> UIWindow {
        let controller = UIHostingController(rootView: view.frame(width: 100, height: 100))
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return window
    }

    private static func unhost(_ window: UIWindow) {
        window.isHidden = true
        window.rootViewController = nil
        // Let SwiftUI tear down subscriptions before presenting the next view. Event/reset
        // sequences above deliberately never yield to the run loop.
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }

}

#endif
