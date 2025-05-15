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

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum Browser {

    static func navigateTo(
        url: URL,
        method: PaywallComponent.ButtonComponent.URLMethod,
        openURL: OpenURLAction,
        inAppBrowserURL: Binding<URL?>
    ) {
        switch method {
        case .inAppBrowser:
#if os(tvOS)
            // There's no SafariServices on tvOS, so we're falling back to opening in an external browser.
            Logger.warning(Strings.no_in_app_browser_tvos)
            openURL(url) { success in
                if success {
                    Logger.debug(Strings.successfully_opened_url_external_browser(url.absoluteString))
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
#else
            openURL(url) { success in
                if success {
                    Logger.debug(Strings.successfully_opened_url_external_browser(url.absoluteString))
                } else {
                    Logger.error(Strings.failed_to_open_url_external_browser(url.absoluteString))
                }
            }
#endif
        case .deepLink:
#if os(watchOS)
            // watchOS doesn't support openURL with a completion handler, so we're just opening the URL.
            openURL(url)
#else
            openURL(url) { success in
                if success {
                    Logger.debug(Strings.successfully_opened_url_deep_link(url.absoluteString))
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
