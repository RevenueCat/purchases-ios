//
//  PaywalError.swift
//  
//
//  Created by Nacho Soto on 7/21/23.
//

import Foundation

/// Error produced when displaying paywalls.
enum PaywallError: Error {

    /// `Purchases` has not been configured yet.
    case purchasesNotConfigured

    /// RevenueCat dashboard does not have a current offering configured.
    case noCurrentOffering

}

extension PaywallError: CustomNSError {

    var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.description
        ]
    }

    private var description: String {
        switch self {
        case .purchasesNotConfigured:
            return "Purchases instance has not been configured yet."

        case .noCurrentOffering:
            return "The RevenueCat dashboard does not have a current offering configured."
        }
    }

}
