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

    init(
        component: PaywallComponent.PurchaseButtonComponent,
        offering: Offering,
        stackViewModel: StackComponentViewModel
    ) {
        self.component = component
        self.offering = offering
        self.stackViewModel = stackViewModel
    }

    var action: PaywallComponent.PurchaseButtonComponent.Action? {
        return self.component.action
    }

    var offeringWebCheckoutUrl: URL? {
        if let customUrl = component.customUrl {
            return customUrl.url
        } else {
            return self.offering.webCheckoutUrl
        }
    }

    var webAutoDimiss: Bool {
        return self.component.webAutoDismiss
    }

    func urlForWebProduct(packageContext: PackageContext) -> URL? {
        guard let package = packageContext.package else {
            return nil
        }

        if let customUrl = component.customUrl {
            // Appends package identifier into a query param to a custom url
            return customUrl.url.appending(name: customUrl.packageParam, value: package.identifier)
        } else {
            return package.webCheckoutUrl
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
