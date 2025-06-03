//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageProducts.swift
//
//  Created by Antonio Rico Diez on 7/5/25.

import Foundation

/// Contains information about all the products available for a Package.
@objc(RCPackageProducts) public final class PackageProducts: NSObject {

    /// The native product attached to the package if available
    public let nativeProduct: StoreProduct?
    /// The web billing product attached to the package if available
    public let webBillingProduct: StoreProduct?

    init(nativeProduct: StoreProduct?,
         webBillingProduct: StoreProduct?) {
        self.nativeProduct = nativeProduct
        self.webBillingProduct = webBillingProduct
    }

}

extension PackageProducts: Sendable {}
