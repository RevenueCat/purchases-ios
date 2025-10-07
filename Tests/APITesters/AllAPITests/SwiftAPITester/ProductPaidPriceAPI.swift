//
//  ProductPaidPriceAPI.swift
//  SwiftAPITester
//
//  Created by Facundo Menzella on 3/10/25.
//

import RevenueCat

var productPaidPrice: ProductPaidPrice!

func checkProductPaidPriceAPI() {
    _ = ProductPaidPrice(currency: "USD", amount: 4.99)
    _ = ProductPaidPrice(currency: "USD", amount: 4.99, locale: .current)
    
    let _: String = productPaidPrice.currency
    let _: Double = productPaidPrice.amount
    let _: String = productPaidPrice.formatted
}
