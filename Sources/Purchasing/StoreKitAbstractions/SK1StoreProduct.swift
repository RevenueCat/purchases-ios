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
    private let priceFormatterProvider: PriceFormatterProvider = .init()

    var productCategory: StoreProduct.ProductCategory {
        guard #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *) else {
            return .nonSubscription
        }

        return self.subscriptionPeriod == nil
            ? .nonSubscription
            : .subscription
    }

    var productType: StoreProduct.ProductType {
        Logger.debug(Strings.storeKit.sk1_no_known_product_type)

        return .defaultType
    }

    var localizedDescription: String { return underlyingSK1Product.localizedDescription }

    var currencyCode: String? { return underlyingSK1Product.priceLocale.rc_currencyCode }

    var price: Decimal { return underlyingSK1Product.price as Decimal }

    var localizedPriceString: String {
        return self.priceFormatter?.string(from: underlyingSK1Product.price) ?? ""
    }

    var productIdentifier: String { return underlyingSK1Product.productIdentifier }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    var isFamilyShareable: Bool { underlyingSK1Product.isFamilyShareable }

    var localizedTitle: String { underlyingSK1Product.localizedTitle }

    var subscriptionGroupIdentifier: String? { underlyingSK1Product.subscriptionGroupIdentifier }

    var priceFormatter: NumberFormatter? {
        return self.priceFormatterProvider.priceFormatterForSK1(with: self.underlyingSK1Product.priceLocale)
    }

    var subscriptionPeriod: SubscriptionPeriod? {
        guard let skSubscriptionPeriod = underlyingSK1Product.subscriptionPeriod,
                skSubscriptionPeriod.numberOfUnits > 0 else {
            return nil
        }
        return SubscriptionPeriod.from(sk1SubscriptionPeriod: skSubscriptionPeriod)
    }

    var introductoryDiscount: StoreProductDiscount? {
        return self.underlyingSK1Product.introductoryPrice
            .flatMap(StoreProductDiscount.init)
    }

    var discounts: [StoreProductDiscount] {
        return self.underlyingSK1Product.discounts
            .compactMap(StoreProductDiscount.init)
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
