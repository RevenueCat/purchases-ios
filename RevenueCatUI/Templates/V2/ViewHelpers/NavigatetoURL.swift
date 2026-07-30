//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NavigatetoURL.swift
//
//  Created by Josh Holtz on 5/15/25.

@_spi(Internal) import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum Browser {

    /// - Parameter onURLOpened: Called with the opened URL once it was successfully opened. Not called if opening
    /// failed, or if `method` is unknown. On watchOS it's called without waiting for the result, because `openURL`
    /// doesn't report one there.
    ///
    /// For `.inAppBrowser` this only reports the tvOS fallback, which opens an external browser. Everywhere else
    /// the in-app browser is presented by the caller through `inAppBrowserURL`, so the caller reports it once the
    /// browser is actually on screen. Assigning the binding isn't enough: the sheet doesn't present if one is
    /// already up, if the paywall is dismissed in the same runloop, or on platforms without `SafariServices`.
    static func navigateTo(
        url: URL,
        method: PaywallComponent.ButtonComponent.URLMethod,
        openURL: OpenURLAction,
        inAppBrowserURL: Binding<URL?>,
        onURLOpened: @escaping (URL) -> Void = { _ in }
    ) {
        switch method {
        case .inAppBrowser:
#if os(tvOS)
            // There's no SafariServices on tvOS, so we're falling back to opening in an external browser.
            Logger.warning(Strings.no_in_app_browser_tvos)
            openURL(url) { success in
                if success {
                    Logger.debug(Strings.successfully_opened_url_external_browser(url.absoluteString))
                    onURLOpened(url)
                } else {
                    Logger.error(Strings.failed_to_open_url_external_browser(url.absoluteString))
                }
            }
#else
            inAppBrowserURL.wrappedValue = url
#endif
        case .externalBrowser:
#if os(watchOS)
            // watchOS doesn't support openURL with a completion handler, so we're just opening the URL.
            openURL(url)
            onURLOpened(url)
#else
            openURL(url) { success in
                if success {
                    Logger.debug(Strings.successfully_opened_url_external_browser(url.absoluteString))
                    onURLOpened(url)
                } else {
                    Logger.error(Strings.failed_to_open_url_external_browser(url.absoluteString))
                }
            }
#endif
        case .deepLink:
#if os(watchOS)
            // watchOS doesn't support openURL with a completion handler, so we're just opening the URL.
            openURL(url)
            onURLOpened(url)
#else
            openURL(url) { success in
                if success {
                    Logger.debug(Strings.successfully_opened_url_deep_link(url.absoluteString))
                    onURLOpened(url)
                } else {
                    Logger.error(Strings.failed_to_open_url_deep_link(url.absoluteString))
                }
            }
#endif
        case .unknown:
            break
        }
    }

}
