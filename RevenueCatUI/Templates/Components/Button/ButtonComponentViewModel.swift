//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ButtonComponentViewModel.swift
//
//  Created by Jay Shortway on 02/10/2024.
//
// swiftlint:disable missing_docs

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class ButtonComponentViewModel {

    private let component: PaywallComponent.ButtonComponent
    private let localizedStrings: PaywallComponent.LocalizationDictionary
    let stackViewModel: StackComponentViewModel

    init(
        component: PaywallComponent.ButtonComponent,
        locale: Locale,
        localizedStrings: PaywallComponent.LocalizationDictionary,
        offering: Offering
    ) throws {
        self.component = component
        self.localizedStrings = localizedStrings
        self.stackViewModel = try StackComponentViewModel(
            locale: locale,
            component: component.stack,
            localizedStrings: localizedStrings,
            offering: offering
        )
    }

    func onClick() {
        switch component.action {
        case .restorePurchases:
            // swiftlint:disable:next todo
            // TODO handle restoring purchases
            break
        case .navigateTo(let destination):
            navigateTo(destination: destination)
        case .navigateBack:
            // swiftlint:disable:next todo
            // TODO handle navigating back
            break
        }
    }

    private func navigateTo(destination: PaywallComponent.ButtonComponent.Destination) {
        switch destination {
        case .customerCenter:
            // swiftlint:disable:next todo
            // TODO handle navigating to customer center
            break
        case .URL(let urlLid, let method),
                .privacyPolicy(let urlLid, let method),
                .terms(let urlLid, let method):
            navigateToUrl(urlLid: urlLid, method: method)
        }
    }

    private func navigateToUrl(urlLid: String, method: PaywallComponent.ButtonComponent.URLMethod) {
        guard let urlString = try? localizedStrings.string(key: urlLid),
        let url = URL(string: urlString) else {
            Logger.error(Strings.paywall_invalid_url(urlLid))
            return
        }

        switch method {
        case .inAppBrowser:
            // swiftlint:disable:next todo
            // TODO handle navigating to URL
            break
        case .externalBrowser,
                .deepLink:
            // swiftlint:disable:next todo
            // TODO handle navigating to URL
            break
        }
    }

}

#endif
