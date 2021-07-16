//
//  Product.swift
//  Product
//
//  Created by Andrés Boedo on 7/16/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

public struct Product {
    public let underlyingSK1Product: SKProduct?

    @available(iOS 15.0, tvOS 15.0, watchOS 7.0, macOS 12.0, *)
    public var underlyingSK2Product: StoreKit.Product? {
        return nil
    }

    init(sk1Product: SKProduct) {
        self.underlyingSK1Product = sk1Product
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 7.0, macOS 12.0, *)
    init(sk2Product: StoreKit.Product) {
        self.underlyingSK1Product = nil
    }
}
