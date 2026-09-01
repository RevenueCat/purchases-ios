//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseButtonComponentViewModel.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PurchaseButtonComponentViewModel {

    var componentName: String? {
        component.name
    }
    private let component: PaywallComponent.PurchaseButtonComponent
    private let offering: Offering
    let stackViewModel: StackComponentViewModel

    let customWebCheckoutUrl: URL?

    init(
        localizationProvider: LocalizationProvider,
        component: PaywallComponent.PurchaseButtonComponent,
        offering: Offering,
        stackViewModel: StackComponentViewModel
    ) throws {
        self.component = component
        self.offering = offering
        self.stackViewModel = stackViewModel

        if case let .customWebCheckout(customWebCheckout)? = component.method {
            self.customWebCheckoutUrl = try localizationProvider
                .localizedStrings
                .urlFromLid(customWebCheckout.customUrl.url)
        } else {
            self.customWebCheckoutUrl = nil
        }

    }

    var method: PaywallComponent.PurchaseButtonComponent.Method? {
        return self.component.method ?? self.component.action.flatMap({ action in
            switch action {
            case .inAppCheckout:
                return .inAppCheckout
            case .webCheckout:
                return .webCheckout(.init(autoDismiss: true, openMethod: .externalBrowser))
            case .webProductSelection:
                return .webProductSelection(.init(autoDismiss: true, openMethod: .externalBrowser))
            }
        })
    }

    typealias LaunchWebCheckout = (url: URL, method: PaywallComponent.ButtonComponent.URLMethod, autoDismiss: Bool)

    /// PoC: routes every web checkout through the in-app `WKWebView` sheet, ignoring the open method and
    /// auto-dismiss configured on the dashboard. Set to `false` to restore server-driven behaviour.
    private static let forcesInAppWebCheckout = true

    /// PoC: rewrite `pay.rev.cat` checkout URLs to the local `rc-billing-checkout` vite server
    /// (`pnpm run dev` on port 3003). Path and query stay intact. Set to `nil` to hit production.
    private static let localWebCheckoutOrigin = URL(string: "https://localhost:3003")

    func urlForWebCheckout(
        packageContext: PackageContext?,
        appUserID: String,
        isSandbox: Bool
    ) -> LaunchWebCheckout? {
        guard let launchWebCheckout = self.configuredUrlForWebCheckout(
            packageContext: packageContext,
            appUserID: appUserID,
            isSandbox: isSandbox
        ) else {
            return nil
        }

        guard Self.forcesInAppWebCheckout else {
            return launchWebCheckout
        }

        // Keeping the paywall on screen lets the sheet own the checkout lifecycle.
        return (
            Self.rewritingToLocalDirectCheckout(
                launchWebCheckout.url,
                packageId: packageContext?.package?.identifier
            ),
            .inAppBrowser,
            false
        )
    }

    /// Rewrites `pay.rev.cat` → local vite, and lands on `/checkout?package_id=` so we skip
    /// the WPL package-selection page (that page still uses the old centred spinner).
    private static func rewritingToLocalDirectCheckout(_ url: URL, packageId: String?) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        if let origin = localWebCheckoutOrigin, components.host == "pay.rev.cat" {
            components.scheme = origin.scheme
            components.host = origin.host
            components.port = origin.port
        }

        let path = components.path
        if !path.hasSuffix("/checkout") && !path.hasSuffix("/checkout/") {
            let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            components.path = "/\(trimmed)/checkout"
        }

        var items = components.queryItems ?? []
        if let packageId, !items.contains(where: { $0.name == "package_id" }) {
            items.append(URLQueryItem(name: "package_id", value: packageId))
        }
        if !items.contains(where: { $0.name == "rc_source" }) {
            items.append(URLQueryItem(name: "rc_source", value: "app"))
        }
        components.queryItems = items

        return components.url ?? url
    }

    private func configuredUrlForWebCheckout(
        packageContext: PackageContext?,
        appUserID: String,
        isSandbox: Bool
    ) -> LaunchWebCheckout? {
        guard let method = self.method else {
            return nil
        }

        switch method {
        case .inAppCheckout, .unknown:
            return nil
        case .webCheckout(let webCheckout):
            if let checkoutUrl = packageContext?.package?.webCheckoutUrl ?? offering.webCheckoutUrl {
                return (checkoutUrl, webCheckout.openMethod ?? .externalBrowser, webCheckout.autoDismiss ?? true)
            } else {
                return nil
            }
        case .webProductSelection(let webCheckout):
            if let checkoutUrl = offering.webCheckoutUrl {
                return (checkoutUrl, webCheckout.openMethod ?? .externalBrowser, webCheckout.autoDismiss ?? true)
            } else {
                return nil
            }
        case .customWebCheckout(let customWebCheckout):
            guard let customUrl = self.customWebCheckoutUrl else {
                return nil
            }

            let url = Self.resolvedCustomWebCheckoutUrl(
                customUrl,
                configuration: customWebCheckout.customUrl,
                package: packageContext?.package,
                appUserID: appUserID,
                isSandbox: isSandbox
            )

            return (url,
                    customWebCheckout.openMethod ?? .externalBrowser,
                    customWebCheckout.autoDismiss ?? true)
        }
    }

    private static func resolvedCustomWebCheckoutUrl(
        _ url: URL,
        configuration: PaywallComponent.PurchaseButtonComponent.CustomWebCheckout.CustomURL,
        package: Package?,
        appUserID: String,
        isSandbox: Bool
    ) -> URL {
        var queryItems = [URLQueryItem(name: Self.sourceParam, value: Self.sourceValue)]

        if let appUserIDParam = configuration.appUserIDParam {
            queryItems.append(.init(name: appUserIDParam, value: appUserID))
        }

        if let envParam = configuration.envParam {
            queryItems.append(.init(name: envParam, value: isSandbox ? Self.sandboxEnvValue : Self.productionEnvValue))
        }

        if let packageParam = configuration.packageParam, let package {
            queryItems.append(.init(name: packageParam, value: package.identifier))
        }

        return url.upserting(queryItems)
    }

    private static let sourceParam = "rc_source"
    private static let sourceValue = "app"
    private static let sandboxEnvValue = "sandbox"
    private static let productionEnvValue = "production"

}

private extension URL {

    /// Replaces any same-named item, leaving other query items and the fragment byte-for-byte intact.
    func upserting(_ newItems: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        let replacedNames = Set(newItems.map(\.name))
        let kept = (components.percentEncodedQueryItems ?? []).filter {
            !replacedNames.contains($0.name.removingPercentEncoding ?? $0.name)
        }

        components.percentEncodedQueryItems = kept + newItems.map(\.percentEncoded)

        return components.url ?? self
    }

}

private extension URLQueryItem {

    /// Stricter than `urlQueryAllowed`, which leaves `+` intact for servers to read as a space.
    var percentEncoded: URLQueryItem {
        return .init(name: self.name.encodedForQuery, value: self.value?.encodedForQuery)
    }

}

private extension String {

    var encodedForQuery: String {
        return self.addingPercentEncoding(withAllowedCharacters: Self.queryParameterAllowed) ?? self
    }

    private static let queryParameterAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?#")
        return allowed
    }()

}

#endif
