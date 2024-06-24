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
        self._underlyingSK2Product = .init(sk2Product)
    }

    // We can't directly store instances of StoreKit.Product, since that causes
    // linking issues in iOS < 15, even with @available checks correctly in place.
    // See https://openradar.appspot.com/radar?id=4970535809187840 / https://github.com/apple/swift/issues/58099
    // Those bugs are fixed, but still cause crashes on iOS 12: https://github.com/RevenueCat/purchases-unity/issues/278
    private let _underlyingSK2Product: Box<SK2Product>
    var underlyingSK2Product: SK2Product { self._underlyingSK2Product.value }

    private let priceFormatterProvider: PriceFormatterProvider = .init()

    var productCategory: StoreProduct.ProductCategory {
        return self.productType.productCategory
    }

    var productType: StoreProduct.ProductType {
        return .init(self.underlyingSK2Product.type)
    }

    var localizedDescription: String { underlyingSK2Product.description }

    var currencyCode: String? { self._currencyCodeAndLocale.code }

    var price: Decimal { underlyingSK2Product.price }

    var localizedPriceString: String { underlyingSK2Product.displayPrice }

    var productIdentifier: String { underlyingSK2Product.id }

    var isFamilyShareable: Bool { underlyingSK2Product.isFamilyShareable }

    var localizedTitle: String { underlyingSK2Product.displayName }

    var priceFormatter: NumberFormatter? {
        let (currencyCode, locale) = self._currencyCodeAndLocale

        guard let currencyCode else {
            Logger.appleError("Can't initialize priceFormatter for SK2 product! Could not find the currency code")
            return nil
        }

        return self.priceFormatterProvider.priceFormatterForSK2(
            withCurrencyCode: currencyCode,
            locale: locale ?? .autoupdatingCurrent
        )
    }

    var subscriptionGroupIdentifier: String? {
        underlyingSK2Product.subscription?.subscriptionGroupID
    }

    var subscriptionPeriod: SubscriptionPeriod? {
        guard let skSubscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
            return nil
        }
        return SubscriptionPeriod.from(sk2SubscriptionPeriod: skSubscriptionPeriod)
    }

    var introductoryDiscount: StoreProductDiscount? {
        self.underlyingSK2Product.subscription?.introductoryOffer
            .flatMap { StoreProductDiscount(sk2Discount: $0, currencyCode: self.currencyCode) }
    }

    var discounts: [StoreProductDiscount] {
        (self.underlyingSK2Product.subscription?.promotionalOffers ?? [])
            .compactMap { StoreProductDiscount(sk2Discount: $0, currencyCode: self.currencyCode) }
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension SK2StoreProduct {

    // swiftlint:disable:next identifier_name
    var _currencyCodeAndLocale: (code: String?, locale: Locale?) {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            let format = self.currencyFormat
            return (format.currencyCode, format.locale)
        } else {
            // note: if we ever need more information from the jsonRepresentation object, we
            // should use Codable or another decoding method to clean up this code.
            let attributes = jsonDict["attributes"] as? [String: Any]
            let offers = attributes?["offers"] as? [[String: Any]]
            return (
                code: offers?.first?["currencyCode"] as? String,
                locale: nil // Not available inside of `jsonRepresentation`
            )
        }
    }

    private var jsonDict: [String: Any] {
        let decoded = try? JSONSerialization.jsonObject(with: self.underlyingSK2Product.jsonRepresentation, options: [])
        return decoded as? [String: Any] ?? [:]
    }

    // This is marked as `@_backDeploy` but for some reason only returns a non-empty string on iOS 16+.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    private var currencyFormat: Decimal.FormatStyle.Currency {
        return self.underlyingSK2Product.priceFormatStyle
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
