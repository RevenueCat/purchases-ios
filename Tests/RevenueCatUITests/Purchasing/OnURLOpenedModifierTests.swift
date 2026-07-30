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
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

/// Verifies the `.onURLOpened` modifier's `PreferenceKey` plumbing.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class OnURLOpenedModifierTests: TestCase {

    private static let url = URL(string: "https://revenuecat.com/terms")!

    func testOnURLOpenedReceivesTheOpenedURL() {
        let handler: PurchaseHandler = .mock()
        let openedURLs: Atomic<[URL]> = .init([])

        let view = ProbeView(handler: handler) { url in
            openedURLs.modify { $0.append(url) }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        expect(openedURLs.value).to(beEmpty())

        // Mutating the handler directly isolates the preference/modifier plumbing from gesture handling.
        handler.signalURLOpened(Self.url)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(openedURLs.value) == [Self.url]
    }

    func testOnURLOpenedFiresAgainForTheSameURL() {
        let handler: PurchaseHandler = .mock()
        let openedURLs: Atomic<[URL]> = .init([])

        let view = ProbeView(handler: handler) { url in
            openedURLs.modify { $0.append(url) }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        handler.signalURLOpened(Self.url)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        // Must fire again, not be deduped as an identical value.
        handler.signalURLOpened(Self.url)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        expect(openedURLs.value) == [Self.url, Self.url]
    }

    func testOnURLOpenedFiresEvenWhenResetImmediatelyAfter() {
        let handler: PurchaseHandler = .mock()
        let openedURLs: Atomic<[URL]> = .init([])

        let view = ProbeView(handler: handler) { url in
            openedURLs.modify { $0.append(url) }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        // Mirrors handleMainPaywallDismiss: signal then immediately reset, no RunLoop spin in between.
        handler.signalURLOpened(Self.url)
        handler.resetForNewSession()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        expect(openedURLs.value) == [Self.url]
    }

    func testResetForNewSessionDeferredClearDoesNotWipeANewerSignal() {
        // resetForNewSession's deferred clear is still pending when the same handler is reused for a new
        // session that signals again within the same tick. The stale clear must not wipe the newer signal.
        let handler: PurchaseHandler = .mock()

        handler.signalURLOpened(Self.url)
        handler.resetForNewSession()
        // New session immediately reuses the same handler and signals again, same tick.
        handler.signalURLOpened(Self.url)
        let newSessionSignal = handler.urlOpened

        RunLoop.main.run(until: Date().addingTimeInterval(0.3))

        expect(handler.urlOpened) == newSessionSignal
    }

    func testOnURLOpenedDoesNotFireOnNewViewAfterExitOfferClear() {
        // clearURLOpened() must complete synchronously so a new view reusing this handler
        // (the exit offer) doesn't see the stale signal as its own fresh one.
        let handler: PurchaseHandler = .mock()
        handler.signalURLOpened(Self.url)
        handler.clearURLOpened()

        let openedURLs: Atomic<[URL]> = .init([])
        let view = ProbeView(handler: handler) { url in
            openedURLs.modify { $0.append(url) }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(openedURLs.value).to(beEmpty())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ProbeView: View {

    @ObservedObject var handler: PurchaseHandler
    let onURLOpened: URLOpenedHandler

    var body: some View {
        Color.clear
            .preference(key: URLOpenedPreferenceKey.self, value: self.handler.urlOpened)
            .onURLOpened(self.onURLOpened)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension OnURLOpenedModifierTests {

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
