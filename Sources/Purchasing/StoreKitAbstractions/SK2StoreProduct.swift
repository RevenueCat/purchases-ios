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
        self.compoundProductIdentifier = CompoundProductIdentifier(for: sk2Product)
        self.installmentsInfo = nil
        #if compiler(>=6.3.2)
        self._pricingTerms = nil
        #endif
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    init(
        sk2Product: SK2Product,
        compoundProductIdentifier: CompoundProductIdentifier,
        installmentsInfo: InstallmentsInfo? = nil
    ) {
        self._underlyingSK2Product = .init(sk2Product)
        self.compoundProductIdentifier = compoundProductIdentifier
        self.installmentsInfo = installmentsInfo
        #if compiler(>=6.3.2)
        self._pricingTerms = Self.pricingTerms(for: sk2Product, installmentsInfo: installmentsInfo)
        #endif
    }

    // We can't directly store instances of StoreKit.Product, since that causes
    // linking issues in iOS < 15, even with @available checks correctly in place.
    // See https://openradar.appspot.com/radar?id=4970535809187840 / https://github.com/apple/swift/issues/58099
    // Those bugs are fixed, but still cause crashes on iOS 12: https://github.com/RevenueCat/purchases-unity/issues/278
    private let _underlyingSK2Product: Box<SK2Product>
    var underlyingSK2Product: SK2Product { self._underlyingSK2Product.value }

    private let compoundProductIdentifier: CompoundProductIdentifier

    private let priceFormatterProvider: PriceFormatterProvider = .init()

    let installmentsInfo: InstallmentsInfo?

    #if compiler(>=6.3.2)
    private let _pricingTerms: (any Sendable)?
    #endif

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

    var productIdentifier: String { return underlyingSK2Product.id }

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
        func introductoryDiscountOnProduct() -> StoreProductDiscount? {
            return self.underlyingSK2Product.subscription?.introductoryOffer
                .flatMap { StoreProductDiscount(sk2Discount: $0, currencyCode: self.currencyCode) }
        }

        #if compiler(>=6.3.2)
        if self.compoundProductIdentifier.productPlanIdentifier != nil,
           #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *) {

            return self.pricingTerms?.subscriptionOffers
                .filter({ $0.type == .introductory })
                .first
                .flatMap { StoreProductDiscount(sk2Discount: $0, currencyCode: self.currencyCode) }
        } else {
            return introductoryDiscountOnProduct()
        }
        #else
        return introductoryDiscountOnProduct()
        #endif
    }

    var discounts: [StoreProductDiscount] {
        #if compiler(>=6.3.2)
        if self.compoundProductIdentifier.productPlanIdentifier != nil,
           #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *) {
            let promotionalOffersOnApplicablePricingTerms = self.pricingTerms
                .map({
                    $0.subscriptionOffers.filter({ $0.type == .promotional })
                        .compactMap { StoreProductDiscount(sk2Discount: $0, currencyCode: self.currencyCode) }
                }) ?? []

            return promotionalOffersOnApplicablePricingTerms
        } else {
            return self.promotionalOffersOnSubscriptionInfo
        }
        #else
        return self.promotionalOffersOnSubscriptionInfo
        #endif
    }

    var id: String { return self.compoundProductIdentifier.compoundProductIdentifier }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension SK2StoreProduct {
    var promotionalOffersOnSubscriptionInfo: [StoreProductDiscount] {
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

#if compiler(>=6.3.2)
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension SK2StoreProduct {
    func containsSubscriptionOfferTypeOnBillingPlan(
        subscriptionOfferType: StoreKit.Product.SubscriptionOffer.OfferType
    ) -> Bool {
        if #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *) {
            guard let pricingTerms = self.pricingTerms else { return false }

            return pricingTerms.subscriptionOffers.contains(where: {
                $0.type == subscriptionOfferType
            })
        } else {
            // Billing plan doesn't exist
            return false
        }
    }
}

@available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
private extension SK2StoreProduct {

    var pricingTerms: StoreKit.Product.SubscriptionInfo.PricingTerms? {
        return self._pricingTerms as? StoreKit.Product.SubscriptionInfo.PricingTerms
    }

    static func pricingTerms(
        for sk2Product: SK2Product,
        installmentsInfo: InstallmentsInfo?
    ) -> StoreKit.Product.SubscriptionInfo.PricingTerms? {
        guard let billingPlan = installmentsInfo?.billingPlanType else {
            return nil
        }

        return sk2Product
            .subscription?
            .pricingTerms
            .first(where: { $0.billingPlanType == billingPlan.skBillingPlanType })
    }
}

#endif

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension SK2StoreProduct: Hashable {

    static func == (lhs: SK2StoreProduct, rhs: SK2StoreProduct) -> Bool {
        return (lhs.compoundProductIdentifier == rhs.compoundProductIdentifier)
            && (lhs.underlyingSK2Product == rhs.underlyingSK2Product)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.compoundProductIdentifier)
        hasher.combine(self.underlyingSK2Product)
    }

}
