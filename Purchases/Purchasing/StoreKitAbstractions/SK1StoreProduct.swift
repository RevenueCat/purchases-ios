//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK1StoreProduct.swift
//
//  Created by Nacho Soto on 12/20/21.

import StoreKit

internal struct SK1StoreProduct: StoreProductType {

    init(sk1Product: SK1Product) {
        self.underlyingSK1Product = sk1Product
    }

    let underlyingSK1Product: SK1Product

    var localizedDescription: String { return underlyingSK1Product.localizedDescription }

    var price: Decimal { return underlyingSK1Product.price as Decimal }

    var localizedPriceString: String {
        return priceFormatter?.string(from: underlyingSK1Product.price) ?? ""
    }

    var productIdentifier: String { return underlyingSK1Product.productIdentifier }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    var isFamilyShareable: Bool { underlyingSK1Product.isFamilyShareable }

    var localizedTitle: String { underlyingSK1Product.localizedTitle }

    @available(iOS 12.0, macCatalyst 13.0, tvOS 12.0, macOS 10.14, watchOS 6.2, *)
    var subscriptionGroupIdentifier: String? { underlyingSK1Product.subscriptionGroupIdentifier }

    var priceFormatter: NumberFormatter? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = underlyingSK1Product.priceLocale
        return formatter
    }

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    var subscriptionPeriod: SubscriptionPeriod? {
        guard let skSubscriptionPeriod = underlyingSK1Product.subscriptionPeriod else {
            return nil
        }
        return SubscriptionPeriod.from(sk1SubscriptionPeriod: skSubscriptionPeriod)
    }

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    var introductoryPrice: PromotionalOffer? {
        return self.underlyingSK1Product.introductoryPrice
            .map(PromotionalOffer.init)
    }

    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    var discounts: [PromotionalOffer] {
        return self.underlyingSK1Product.discounts
            .map(PromotionalOffer.init)
    }

}

extension SK1StoreProduct: Hashable {

    static func == (lhs: SK1StoreProduct, rhs: SK1StoreProduct) -> Bool {
        return lhs.underlyingSK1Product == rhs.underlyingSK1Product
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.underlyingSK1Product)
    }

}
