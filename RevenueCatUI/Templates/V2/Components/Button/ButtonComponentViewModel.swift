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

import Foundation
@_spi(Internal) import RevenueCat
#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ButtonComponentViewModel {

    /// A mirror of ButtonComponent.Action, with the sole purpose of being able to change the type of urlLid parameters
    /// of some Destination's to actual URLs.
    enum Action {
        case restorePurchases
        case navigateTo(destination: Destination)
        case sheet(RevenueCat.PaywallComponent.ButtonComponent.Sheet)
        case navigateBack
        case unknown
    }

    /// A mirror of ButtonComponent.Destination, with any urlLid parameters changed to be of the actual URL type. This
    /// allows us to verify the URLs exist and are properly formatted, before making them available to the view layer.
    /// This way the view layer doesn't need to handle this error scenario.
    enum Destination {
        case customerCenter
        case offerCodeRedemptionSheet
        case url(url: URL, method: PaywallComponent.ButtonComponent.URLMethod)
        case privacyPolicy(url: URL, method: PaywallComponent.ButtonComponent.URLMethod)
        case terms(url: URL, method: PaywallComponent.ButtonComponent.URLMethod)
        case webPaywallLink(url: URL, method: PaywallComponent.ButtonComponent.URLMethod)
        case unknown
    }

    let component: PaywallComponent.ButtonComponent
    let localizationProvider: LocalizationProvider
    let action: Action
    let stackViewModel: StackComponentViewModel
    let sheetStackViewModel: StackComponentViewModel?

    // swiftlint:disable:next cyclomatic_complexity
    init(
        component: PaywallComponent.ButtonComponent,
        localizationProvider: LocalizationProvider,
        offering: Offering,
        stackViewModel: StackComponentViewModel,
        sheetStackViewModel: StackComponentViewModel? = nil
    ) throws {
        self.component = component
        self.localizationProvider = localizationProvider
        self.stackViewModel = stackViewModel
        self.sheetStackViewModel = sheetStackViewModel

        let localizedStrings = localizationProvider.localizedStrings

        // Mapping ButtonComponent.Action to ButtonComponentViewModel.Action to verify that any passed-in urlLids exist
        // in localizedStrings:
        switch component.action {
        case .restorePurchases:
            self.action = .restorePurchases
        case .navigateTo(let destination):
            switch destination {
            case .customerCenter:
                self.action = .navigateTo(destination: .customerCenter)
            case .offerCode:
                self.action = .navigateTo(destination: .offerCodeRedemptionSheet)
            case .url(let urlLid, let method):
                self.action = .navigateTo(
                    destination: .url(url: try localizedStrings.urlFromLid(urlLid), method: method)
                )
            case .privacyPolicy(let urlLid, let method):
                self.action = .navigateTo(
                    destination: .privacyPolicy(url: try localizedStrings.urlFromLid(urlLid), method: method)
                )
            case .terms(let urlLid, let method):
                self.action = .navigateTo(
                    destination: .terms(url: try localizedStrings.urlFromLid(urlLid), method: method)
                )
            case .webPaywallLink(urlLid: let urlLid, method: let method):
                self.action = .navigateTo(
                    destination: .webPaywallLink(url: try localizedStrings.urlFromLid(urlLid), method: method)
                )
            case .unknown:
                self.action = .unknown
            case .sheet(let sheet):
                self.action = .sheet(sheet)
            }
        case .navigateBack:
            self.action = .navigateBack
        case .unknown:
            self.action = .unknown
        }
    }

    var hasUnknownAction: Bool {
        switch self.action {
        case .navigateTo(destination: let destination):
            if case .offerCodeRedemptionSheet = destination {
#if os(iOS) && !targetEnvironment(macCatalyst)
                    return false
#else
                    return true
#endif
            } else {
                return false
            }
        case .unknown: return true
        default: return false
        }
    }

    var isRestoreAction: Bool {
        switch self.action {
        case .restorePurchases:
            return true
        case .navigateTo:
            return false
        case .navigateBack:
            return false
        case .unknown:
            return false
        case .sheet:
            return false
        }
    }

}

#endif
