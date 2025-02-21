//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitErrorHelper.swift
//
//  Created by Cesar de la Vega on 19/9/24.

import StoreKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum StoreKitErrorUtils {

    static func extractStoreKitErrorDescription(from error: Error?) -> String? {
        guard let underlyingError = (error as NSError?)?.userInfo[NSUnderlyingErrorKey] as? Error else {
            return nil
        }

        if let skError = underlyingError as? SKError {
            return skError.code.trackingDescription
        } else if let storeKitError = underlyingError as? StoreKitError {
            return storeKitError.trackingDescription
        } else if let storeKitError = underlyingError as? StoreKit.Product.PurchaseError {
            return storeKitError.trackingDescription
        } else {
            return Self.extractStoreKitErrorDescription(from: underlyingError)
        }
    }

}
