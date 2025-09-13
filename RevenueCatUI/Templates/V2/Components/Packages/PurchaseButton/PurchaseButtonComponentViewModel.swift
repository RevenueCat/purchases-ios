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
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PurchaseButtonComponentViewModel {

    private let component: PaywallComponent.PurchaseButtonComponent
    private let offering: Offering
    let stackViewModel: StackComponentViewModel

    private let customWebCheckoutUrl: URL?

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

    func urlForWebCheckout(packageContext: PackageContext?) -> LaunchWebCheckout? {
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
            if let customUrl = self.customWebCheckoutUrl {
                if let package = packageContext?.package,
                   let packageParam = customWebCheckout.customUrl.packageParam {
                    let url = customUrl.appending(name: packageParam, value: package.identifier)
                    return (url,
                            customWebCheckout.openMethod ?? .externalBrowser,
                            customWebCheckout.autoDismiss ?? true)
                } else {
                    return (customUrl,
                            customWebCheckout.openMethod ?? .externalBrowser,
                            customWebCheckout.autoDismiss ?? true)
                }
            } else {
                return nil
            }
        }
    }

}

private extension URL {

    func appending(name: String, value: String?) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)

        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value))
        components?.queryItems = queryItems

        return components?.url ?? self
    }

}

#endif
