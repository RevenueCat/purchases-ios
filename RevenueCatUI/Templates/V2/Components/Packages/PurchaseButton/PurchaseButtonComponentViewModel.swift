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

    func urlForWebCheckout(
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
        var queryItems: [(name: String, value: String)] = [(Self.sourceParam, Self.sourceValue)]

        if let appUserIDParam = configuration.appUserIDParam {
            queryItems.append((appUserIDParam, appUserID))
        }

        if let envParam = configuration.envParam {
            queryItems.append((envParam, isSandbox ? Self.sandboxEnvValue : Self.productionEnvValue))
        }

        if let packageParam = configuration.packageParam, let package {
            queryItems.append((packageParam, package.identifier))
        }

        return url.upserting(queryItems: queryItems)
    }

    private static let sourceParam = "rc_source"
    private static let sourceValue = "app"
    private static let sandboxEnvValue = "sandbox"
    private static let productionEnvValue = "production"

}

private extension URL {

    /// Adds each item, replacing any same-named item already in the URL and leaving everything else —
    /// unrelated query parameters and the fragment — byte-for-byte intact.
    func upserting(queryItems newItems: [(name: String, value: String)]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        let replacedNames = Set(newItems.map(\.name))
        var items = components.percentEncodedQueryItems ?? []
        items.removeAll { replacedNames.contains($0.name.removingPercentEncoding ?? $0.name) }
        items.append(contentsOf: newItems.map {
            URLQueryItem(name: $0.name.percentEncodedForQuery, value: $0.value.percentEncodedForQuery)
        })
        components.percentEncodedQueryItems = items

        return components.url ?? self
    }

}

private extension String {

    /// `urlQueryAllowed` permits characters that are legal in a query string but ambiguous inside a
    /// single parameter — most notably `+`, which many servers read as a space.
    var percentEncodedForQuery: String {
        return self.addingPercentEncoding(withAllowedCharacters: Self.queryParameterAllowed) ?? self
    }

    private static let queryParameterAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?#")
        return allowed
    }()

}

#endif
