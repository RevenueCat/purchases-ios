//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Error+Extensions.swift
//
//  Created by Joshua Liebowitz on 8/6/21.

import Foundation
import StoreKit

extension NSError {

    var subscriberAttributesErrors: [String: String]? {
        return self.userInfo[ErrorDetails.attributeErrorsKey] as? [String: String]
    }

}

extension Error {

    var isCancelledError: Bool {
        switch self {
        case let error as ErrorCode:
            switch error {
            case .purchaseCancelledError: return true
            default: return false
            }

        case let purchasesError as PurchasesError:
            return purchasesError.error.isCancelledError

        case let error as NSError:
            switch (error.domain, error.code) {
            case (SKErrorDomain, SKError.paymentCancelled.rawValue): return true

            default: return false
            }

        default: return false
        }
    }

}
