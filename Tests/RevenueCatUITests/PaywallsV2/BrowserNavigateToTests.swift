//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BrowserNavigateToTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class BrowserNavigateToTests: TestCase {

    private static let url = URL(string: "https://revenuecat.com/terms")!

    func testExternalBrowserNotifiesWhenOpenSucceeds() {
        let result = self.navigateTo(method: .externalBrowser, openSucceeds: true)

        expect(result.urls) == [Self.url]
        expect(result.inAppBrowserURL).to(beNil())
    }

    func testDeepLinkNotifiesWhenOpenSucceeds() {
        let result = self.navigateTo(method: .deepLink, openSucceeds: true)

        expect(result.urls) == [Self.url]
        expect(result.inAppBrowserURL).to(beNil())
    }

#if os(watchOS)

    // watchOS has no `openURL` completion handler, so there is no result to gate the notification on.

    func testExternalBrowserNotifiesWithoutWaitingForTheResultOnWatchOS() {
        expect(self.navigateTo(method: .externalBrowser, openSucceeds: false).urls) == [Self.url]
    }

    func testDeepLinkNotifiesWithoutWaitingForTheResultOnWatchOS() {
        expect(self.navigateTo(method: .deepLink, openSucceeds: false).urls) == [Self.url]
    }

#else

    func testExternalBrowserDoesNotNotifyWhenOpenFails() {
        expect(self.navigateTo(method: .externalBrowser, openSucceeds: false).urls).to(beEmpty())
    }

    func testDeepLinkDoesNotNotifyWhenOpenFails() {
        expect(self.navigateTo(method: .deepLink, openSucceeds: false).urls).to(beEmpty())
    }

#endif

#if os(tvOS)

    // There's no SafariServices on tvOS, so the in-app browser falls back to an external browser.

    func testInAppBrowserFallsBackToTheExternalBrowserOnTvOS() {
        let result = self.navigateTo(method: .inAppBrowser, openSucceeds: true)

        expect(result.urls) == [Self.url]
        expect(result.inAppBrowserURL).to(beNil())
    }

    func testInAppBrowserFallbackDoesNotNotifyWhenOpenFailsOnTvOS() {
        expect(self.navigateTo(method: .inAppBrowser, openSucceeds: false).urls).to(beEmpty())
    }

#else

    func testInAppBrowserRequestsTheBrowserWithoutNotifying() {
        // Assigning the binding doesn't mean a browser appeared: the sheet doesn't present if one is already up,
        // if the paywall is dismissed in the same runloop, or on platforms without `SafariServices`. The view that
        // presents the browser reports the open instead (see `ButtonComponentView`), which no unit test can drive
        // without a real sheet presentation — it's covered manually in PaywallsTester.
        let result = self.navigateTo(method: .inAppBrowser, openSucceeds: true)

        expect(result.urls).to(beEmpty())
        expect(result.inAppBrowserURL) == Self.url
    }

#endif

    func testUnknownMethodDoesNotNotify() {
        let result = self.navigateTo(method: .unknown, openSucceeds: true)

        expect(result.urls).to(beEmpty())
        expect(result.inAppBrowserURL).to(beNil())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension BrowserNavigateToTests {

    struct Result {
        var urls: [URL]
        var inAppBrowserURL: URL?
    }

    func navigateTo(
        method: PaywallComponent.ButtonComponent.URLMethod,
        openSucceeds: Bool
    ) -> Result {
        let urls: Atomic<[URL]> = .init([])
        let inAppBrowserURL: Atomic<URL?> = .init(nil)

        Browser.navigateTo(
            url: Self.url,
            method: method,
            openURL: OpenURLAction { _ in openSucceeds ? .handled : .discarded },
            inAppBrowserURL: Binding(get: { inAppBrowserURL.value },
                                     set: { inAppBrowserURL.value = $0 }),
            onURLOpened: { url in urls.modify { $0.append(url) } }
        )

        // `openURL`'s completion handler is invoked asynchronously on the main queue.
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        return Result(urls: urls.value, inAppBrowserURL: inAppBrowserURL.value)
    }

}
