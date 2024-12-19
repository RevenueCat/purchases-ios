//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterStoreKitUtilitiesType.swift
//
//  Created by Will Taylor on 12/18/24.

import Foundation
import StoreKit

import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
protocol CustomerCenterStoreKitUtilitiesType {

    func renewalPriceFromRenewalInfo(for product: StoreProduct) async -> (price: Decimal, currencyCode: String)?
}
