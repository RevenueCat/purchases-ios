//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2StoreProduct.swift
//
//  Created by Nacho Soto on 12/20/21.

import StoreKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
internal struct SK2StoreProduct: StoreProductType {

    init(sk2Product: SK2Product) {
        self._underlyingSK2Product = sk2Product
    }

    // We can't directly store instances of StoreKit.Product, since that causes
    // linking issues in iOS < 15, even with @available checks correctly in place.
    // So instead, we store the underlying product as Any and wrap it with casting.
    // https://openradar.appspot.com/radar?id=4970535809187840
    private let _underlyingSK2Product: Any
    var underlyingSK2Product: SK2Product {
        // swiftlint:disable:next force_cast
        _underlyingSK2Product as! SK2Product
    }

    var localizedDescription: String { underlyingSK2Product.description }

    var price: Decimal { underlyingSK2Product.price }

    var localizedPriceString: String { underlyingSK2Product.displayPrice }

    var productIdentifier: String { underlyingSK2Product.id }

    var isFamilyShareable: Bool { underlyingSK2Product.isFamilyShareable }

    var localizedTitle: String { underlyingSK2Product.displayName }

    var priceFormatter: NumberFormatter? {
        // note: if we ever need more information from the jsonRepresentation object, we
        // should use Codable or another decoding method to clean up this code.
        guard let attributes = jsonDict["attributes"] as? [String: Any],
              let offers = attributes["offers"] as? [[String: Any]],
              let currencyCode: String = offers.first?["currencyCode"] as? String else {
                  Logger.appleError("Can't initialize priceFormatter for SK2 product! Could not find the currency code")
                  return nil
              }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .autoupdatingCurrent
        return formatter
    }

    var subscriptionGroupIdentifier: String? {
        underlyingSK2Product.subscription?.subscriptionGroupID
    }

    private var jsonDict: [String: Any] {
        let decoded = try? JSONSerialization.jsonObject(with: self.underlyingSK2Product.jsonRepresentation, options: [])
        return decoded as? [String: Any] ?? [:]
    }

    var subscriptionPeriod: SubscriptionPeriod? {
        guard let skSubscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
            return nil
        }
        return SubscriptionPeriod.from(sk2SubscriptionPeriod: skSubscriptionPeriod)
    }

    var introductoryPrice: PromotionalOffer? {
        self.underlyingSK2Product.subscription?.introductoryOffer
            .map(PromotionalOffer.init)
    }

    var discounts: [PromotionalOffer] {
        (self.underlyingSK2Product.subscription?.promotionalOffers ?? [])
            .compactMap(PromotionalOffer.init)
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension SK2StoreProduct: Hashable {

    static func == (lhs: SK2StoreProduct, rhs: SK2StoreProduct) -> Bool {
        return lhs.underlyingSK2Product == rhs.underlyingSK2Product
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.underlyingSK2Product)
    }

}
