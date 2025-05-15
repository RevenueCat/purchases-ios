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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

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

    var action: PaywallComponent.PurchaseButtonComponent.Action? {
        return self.component.action
    }

    var offeringWebCheckoutUrl: (URL, PaywallComponent.ButtonComponent.URLMethod)? {
        guard let method = component.method else {
            if let url = offering.webCheckoutUrl {
                return (url, .externalBrowser)
            } else {
                return nil
            }
        }

        switch method {
        case .inAppCheckout, .unknown:
            return nil
        case .webCheckout(let webCheckout), .webProductSelection(let webCheckout):
            if let url = offering.webCheckoutUrl {
                return (url, webCheckout.openMethod ?? .externalBrowser)
            } else {
                return nil
            }
        case .customWebCheckout(let customWebCheckout):
            if let url = customWebCheckoutUrl {
                return (url, .externalBrowser)
            } else {
                return nil
            }
        }
    }

    static let defaultWebAutoDismiss = true

    var webAutoDimiss: Bool {
        if let method = component.method {
            switch method {
            case .webCheckout(let webCheckout), .webProductSelection(let webCheckout):
                return webCheckout.autoDismiss ?? Self.defaultWebAutoDismiss
            case .customWebCheckout(let customWebCheckout):
                return customWebCheckout.autoDismiss ?? Self.defaultWebAutoDismiss
            case .inAppCheckout, .unknown:
                break
            }
        } else if component.action != nil {
            // Legacy action was previously always dismissing
            return Self.defaultWebAutoDismiss
        }

        return Self.defaultWebAutoDismiss
    }

    func urlForWebProduct(packageContext: PackageContext) -> (URL, PaywallComponent.ButtonComponent.URLMethod)? {
        guard let package = packageContext.package else {
            return nil
        }

        if let method = component.method {
            switch method {
            case .webCheckout(let webCheckout), .webProductSelection(let webCheckout):
                guard let url = package.webCheckoutUrl else {
                    return nil
                }

                return (url, webCheckout.openMethod ?? .externalBrowser)
            case .customWebCheckout(let customWebCheckout):
                if let customUrl = self.customWebCheckoutUrl {
                    // Appends package identifier into a query param to a custom url
                    if let packageParam = customWebCheckout.customUrl.packageParam {
                        let url = customUrl.appending(name: packageParam, value: package.identifier)
                        return (url, customWebCheckout.openMethod ?? .externalBrowser)
                    } else {
                        return (customUrl, customWebCheckout.openMethod ?? .externalBrowser)
                    }
                } else {
                    return nil
                }
            case .inAppCheckout, .unknown:
                return nil
            }
        }

        guard let url = package.webCheckoutUrl else {
            return nil
        }

        return (url, .externalBrowser)
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
