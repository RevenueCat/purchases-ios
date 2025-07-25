//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebProduct+TestStoreProduct.swift
//
//  Created by Antonio Pallares on 25/7/25.

import Foundation

extension WebProductsResponse.Product {

    func convertToStoreProduct() -> StoreProduct {


        
        let price: Decimal

        if let basePrice = self.purchaseOption?.basePrice {

        }

        return TestStoreProduct(localizedTitle: self.title,
                                price: <#T##Decimal#>,
                                localizedPriceString: <#T##String#>, productIdentifier: <#T##String#>, productType: <#T##StoreProduct.ProductType#>, localizedDescription: <#T##String#>)
    }

    private var purchaseOption: WebProductsResponse.PurchaseOption? {
        if let defaultPurchaseOptionId = self.defaultPurchaseOptionId,
        let defaultPurchaseOption = self.purchaseOptions[defaultPurchaseOptionId] {
            return defaultPurchaseOption
        } else {
            return self.purchaseOptions.first?.value
        }
    }
}
