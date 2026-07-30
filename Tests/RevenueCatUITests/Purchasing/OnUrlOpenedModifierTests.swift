//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OnUrlOpenedModifierTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

/// Verifies the `.onUrlOpened` modifier's `PreferenceKey` plumbing.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class OnUrlOpenedModifierTests: TestCase {

    private static let url = "https://revenuecat.com/terms"

    func testOnUrlOpenedReceivesTheOpenedUrl() {
        let handler: PurchaseHandler = .mock()
        let openedUrls: Atomic<[String]> = .init([])

        let view = ProbeView(handler: handler) { url in
            openedUrls.modify { $0.append(url) }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        expect(openedUrls.value).to(beEmpty())

        // Mutating the handler directly isolates the preference/modifier plumbing from gesture handling.
        handler.signalUrlOpened(Self.url)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(openedUrls.value) == [Self.url]
    }

    func testOnUrlOpenedFiresAgainForTheSameUrl() {
        let handler: PurchaseHandler = .mock()
        let openedUrls: Atomic<[String]> = .init([])

        let view = ProbeView(handler: handler) { url in
            openedUrls.modify { $0.append(url) }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        handler.signalUrlOpened(Self.url)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        // Must fire again, not be deduped as an identical value.
        handler.signalUrlOpened(Self.url)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        expect(openedUrls.value) == [Self.url, Self.url]
    }

    func testOnUrlOpenedFiresEvenWhenResetImmediatelyAfter() {
        let handler: PurchaseHandler = .mock()
        let openedUrls: Atomic<[String]> = .init([])

        let view = ProbeView(handler: handler) { url in
            openedUrls.modify { $0.append(url) }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        // Mirrors handleMainPaywallDismiss: signal then immediately reset, no RunLoop spin in between.
        handler.signalUrlOpened(Self.url)
        handler.resetForNewSession()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        expect(openedUrls.value) == [Self.url]
    }

    func testResetForNewSessionDeferredClearDoesNotWipeANewerSignal() {
        // resetForNewSession's deferred clear is still pending when the same handler is reused for a new
        // session that signals again within the same tick. The stale clear must not wipe the newer signal.
        let handler: PurchaseHandler = .mock()

        handler.signalUrlOpened(Self.url)
        handler.resetForNewSession()
        // New session immediately reuses the same handler and signals again, same tick.
        handler.signalUrlOpened(Self.url)
        let newSessionSignal = handler.urlOpened

        RunLoop.main.run(until: Date().addingTimeInterval(0.3))

        expect(handler.urlOpened) == newSessionSignal
    }

    func testOnUrlOpenedDoesNotFireOnNewViewAfterExitOfferClear() {
        // clearUrlOpened() must complete synchronously so a new view reusing this handler
        // (the exit offer) doesn't see the stale signal as its own fresh one.
        let handler: PurchaseHandler = .mock()
        handler.signalUrlOpened(Self.url)
        handler.clearUrlOpened()

        let openedUrls: Atomic<[String]> = .init([])
        let view = ProbeView(handler: handler) { url in
            openedUrls.modify { $0.append(url) }
        }

        let (window, _) = Self.host(view)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        expect(openedUrls.value).to(beEmpty())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ProbeView: View {

    @ObservedObject var handler: PurchaseHandler
    let onUrlOpened: UrlOpenedHandler

    var body: some View {
        Color.clear
            .preference(key: UrlOpenedPreferenceKey.self, value: self.handler.urlOpened)
            .onUrlOpened(self.onUrlOpened)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension OnUrlOpenedModifierTests {

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
