//
//  ProductsManager.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/14/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import StoreKit

internal class ProductsManager {
    private let cachedProductsByIdentifier: [String: SKProduct] = [:]
    
    func products(withIdentifiers identifiers: Set<String>) -> Set<SKProduct> {
        return Set()
    }
}
