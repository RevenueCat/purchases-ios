//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterError.swift
//
//
//  Created by Cesar de la Vega on 29/5/24.
//

import Foundation

/// Error produced when displaying the customer center.
enum CustomerCenterError: Error, Comparable {

    /// Could not find information for an active subscription.
    case couldNotFindSubscriptionInformation

    /// Could not find offer id for any active product
    case couldNotFindOfferForActiveProducts

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
        case .couldNotFindOfferForActiveProducts:
            return "Could not find any product with specified offer id."
        }
    }

}
