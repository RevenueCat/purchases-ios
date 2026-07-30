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

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class BrowserNavigateToTests: TestCase {

    private static let url = URL(string: "https://revenuecat.com/terms")!

    func testExternalBrowserNotifiesWhenOpenSucceeds() {
        let opened = self.navigateTo(method: .externalBrowser, openSucceeds: true)

        expect(opened.urls) == [Self.url.absoluteString]
        expect(opened.inAppBrowserURL).to(beNil())
    }

    func testExternalBrowserDoesNotNotifyWhenOpenFails() {
        let opened = self.navigateTo(method: .externalBrowser, openSucceeds: false)

        expect(opened.urls).to(beEmpty())
    }

    func testDeepLinkNotifiesWhenOpenSucceeds() {
        let opened = self.navigateTo(method: .deepLink, openSucceeds: true)

        expect(opened.urls) == [Self.url.absoluteString]
    }

    func testDeepLinkDoesNotNotifyWhenOpenFails() {
        let opened = self.navigateTo(method: .deepLink, openSucceeds: false)

        expect(opened.urls).to(beEmpty())
    }

    func testInAppBrowserNotifiesAndPresentsTheBrowser() {
        // The in-app browser is presented as a sheet instead of being handed to `openURL`.
        let opened = self.navigateTo(method: .inAppBrowser, openSucceeds: false)

        expect(opened.urls) == [Self.url.absoluteString]
        expect(opened.inAppBrowserURL) == Self.url
    }

    func testUnknownMethodDoesNotNotify() {
        let opened = self.navigateTo(method: .unknown, openSucceeds: true)

        expect(opened.urls).to(beEmpty())
        expect(opened.inAppBrowserURL).to(beNil())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension BrowserNavigateToTests {

    struct Result {
        var urls: [String]
        var inAppBrowserURL: URL?
    }

    func navigateTo(
        method: PaywallComponent.ButtonComponent.URLMethod,
        openSucceeds: Bool
    ) -> Result {
        let urls: Atomic<[String]> = .init([])
        let inAppBrowserURL: Atomic<URL?> = .init(nil)

        Browser.navigateTo(
            url: Self.url,
            method: method,
            openURL: OpenURLAction { _ in openSucceeds ? .handled : .discarded },
            inAppBrowserURL: Binding(get: { inAppBrowserURL.value },
                                     set: { inAppBrowserURL.value = $0 }),
            onUrlOpened: { url in urls.modify { $0.append(url) } }
        )

        // `openURL`'s completion handler is invoked asynchronously on the main queue.
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        return Result(urls: urls.value, inAppBrowserURL: inAppBrowserURL.value)
    }

}

#endif
