//
//  CustomerCenterError.swift
//
//
//  Created by Cesar de la Vega on 29/5/24.
//

import Foundation

/// Error produced when displaying the customer center.
enum CustomerCenterError: Error {

    /// Could not find information for an active subscription.
    case couldNotFindSubscriptionInformation

}

extension CustomerCenterError: CustomNSError {

    var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.description
        ]
    }

    private var description: String {
        switch self {
        case .couldNotFindSubscriptionInformation:
            return "Could not find information for an active subscription."
        }
    }

}

