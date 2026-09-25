//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseStrings.swift
//
//  Created by Antonio Pallares on 4/9/26.

import Foundation

// swiftlint:disable identifier_name

enum ExternalPurchaseStrings {

    case eligibility_resolved(_ availability: ExternalPurchaseAvailability)
    case custom_link_does_not_apply(_ storefront: String)
    case custom_link_skipped_in_simulator
    case disabled_in_simulator
    case not_eligible
    case payments_not_authorized
    case already_preparing
    case notice_cancelled
    case error_showing_notice(_ error: Error)
    case no_token_available
    case error_requesting_token(_ error: Error)
    case token_registered(_ tokenID: String)
    case error_registering_token(_ error: BackendError)

}

extension ExternalPurchaseStrings: LogMessage {

    var description: String {
        switch self {
        case let .eligibility_resolved(availability):
            return "External purchase availability resolved to \(availability)."
        case let .custom_link_does_not_apply(storefront):
            return "Apple's external purchase custom link does not apply in this customer's storefront " +
            "(\(storefront)): continuing with no notice shown and no token minted."
        case .custom_link_skipped_in_simulator:
            return "Apple's external purchase custom link is not available in the simulator: continuing with " +
            "no notice shown and no token minted, whatever the storefront. Use a device to try that flow out."
        case .disabled_in_simulator:
            return "Not preparing an external purchase: disableExternalPurchasesInSimulator " +
            "makes the simulator behave as a physical device does for a customer who is not eligible for " +
            "external purchases."
        case .not_eligible:
            return "Not preparing an external purchase: Apple's external purchase custom link does not apply " +
            "to this customer."
        case .payments_not_authorized:
            return "Not preparing an external purchase: this device does not authorize payments."
        case .already_preparing:
            return "Not preparing an external purchase: another one is already being prepared."
        case .notice_cancelled:
            return "The customer chose not to continue to the external purchase."
        case let .error_showing_notice(error):
            return "Error showing the external purchase notice: \(error.localizedDescription)"
        case .no_token_available:
            return "StoreKit provided no external purchase token. Registering without one."
        case let .error_requesting_token(error):
            return "Error requesting the external purchase token: \(error.localizedDescription)"
        case let .token_registered(tokenID):
            return "Registered external purchase token \(tokenID)."
        case let .error_registering_token(error):
            return "Error registering the external purchase token: \(error.localizedDescription)"
        }
    }

    var category: String { return "external_purchase" }

}
