//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// Created by Andrés Boedo on 9/14/20.
//

import Foundation

enum Strings {

    static let attribution = AttributionStrings.self
    static let codable = CodableStrings.self
    static let configure = ConfigureStrings.self
    static let backendError = BackendErrorStrings.self
    static let customerInfo = CustomerInfoStrings.self
    static let eligibility = EligibilityStrings.self
    static let identity = IdentityStrings.self
    static let network = NetworkStrings.self
    static let offering = OfferingStrings.self
    static let purchase = PurchaseStrings.self
    static let receipt = ReceiptStrings.self
    static let restore = RestoreStrings.self
    static let signing = SigningStrings.self
    static let storeKit = StoreKitStrings.self

}

extension Strings {

    /// Returns the type and address of the given object, useful for debugging.
    /// Example: StoreKit1Wrapper (0x0000600000e36480)
    static func objectDescription(_ object: AnyObject) -> String {
        return "\(type(of: object)) (\(Strings.address(for: object)))"
    }

    /// Returns the address of the given object, useful for debugging.
    private static func address(for object: AnyObject) -> String {
        return Unmanaged.passUnretained(object).toOpaque().debugDescription
    }

}
