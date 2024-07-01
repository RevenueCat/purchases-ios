//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOfferView.swift
//
//
//  Created by Cesar de la Vega on 17/6/24.
//

import RevenueCat
import StoreKit
import SwiftUI

#if !os(macOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct PromotionalOfferView: View {

    private let appearance: CustomerCenterConfigData.Appearance

    @StateObject
    private var viewModel: PromotionalOfferViewModel
    @Environment(\.dismiss)
    private var dismiss
    private var promotionalOfferId: String

    init(promotionalOfferId: String,
         appearance: CustomerCenterConfigData.Appearance) {
        let viewModel = PromotionalOfferViewModel()
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.promotionalOfferId = promotionalOfferId
        self.appearance = appearance
    }

    init(promotionalOffer: PromotionalOffer,
         product: StoreProduct,
         appearance: CustomerCenterConfigData.Appearance) {
        let viewModel = PromotionalOfferViewModel(product: product, promotionalOffer: promotionalOffer)
        self._viewModel = StateObject(wrappedValue: viewModel)
        // force unwrap since it is only `nil` for SK1 products before iOS 12.2.
        self.promotionalOfferId = promotionalOffer.discount.offerIdentifier!
        self.appearance = appearance
    }

    var body: some View {
        VStack {
            if let discount = viewModel.promotionalOffer?.discount,
               let product = viewModel.product {
                Text("Wait!")
                    .font(.title)
                    .padding()

                Text("Before you go, here’s a one-time offer to continue at a discount.")
                    .font(.title3)
                    .padding()

                Spacer()

                var mainTitle = discount.localizedPricePerPeriodByPaymentMode(.current)
                let localizedProductPricePerPeriod = product.localizedPricePerPeriod(.current)

                Button(action: {
                    Task {
                        await viewModel.purchasePromo()
                    }
                }, label: {
                    VStack {
                        Text(mainTitle)
                            .font(.headline)
                        Text("then \(localizedProductPricePerPeriod)")
                            .font(.subheadline)
                    }
                })
                .buttonStyle(ManageSubscriptionsButtonStyle(appearance: self.appearance))

                Button("No thanks") {
                    dismiss()
                }
            }
        }
        .task {
            await checkAndLoadPromotional()
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
private extension PromotionalOfferView {

    func checkAndLoadPromotional() async {
        guard let discount = self.viewModel.promotionalOffer else {
            return
        }
        await self.viewModel.loadPromo(promotionalOfferId: self.promotionalOfferId)
    }

}

private extension StoreProductDiscount {

    func localizedPricePerPeriodByPaymentMode(_ locale: Locale) -> String {
        let period = self.subscriptionPeriod.periodTitle()

        return switch self.paymentMode {
        case .freeTrial:
            // 3 months for free
            "\(period) for free"
        case .payAsYouGo:
            // $0.99/month for 3 months
            "\(localizedPricePerPeriod(locale)) for \(localizedNumberOfPeriods())"
        case .payUpFront:
            // 3 months for $0.99
            "\(period) for \(self.localizedPriceString)"
        }
    }

    func localizedNumberOfPeriods() -> String {
        let periodString = "\(self.numberOfPeriods) \(self.subscriptionPeriod.durationTitle)"
        let pluralized = self.numberOfPeriods > 1 ?  periodString + "s" : periodString
        return pluralized
    }

    func localizedPricePerPeriod(_ locale: Locale) -> String {
        let unit = Localization.abbreviatedUnitLocalizedString(for: self.subscriptionPeriod, locale: locale)
        return "\(self.localizedPriceString)/\(unit)"
    }

}

private extension StoreProduct {

    func localizedPricePerPeriod(_ locale: Locale) -> String {
        guard let period = self.subscriptionPeriod else {
            return self.localizedPriceString
        }

        let unit = Localization.abbreviatedUnitLocalizedString(for: period, locale: locale)
        return "\(self.localizedPriceString)/\(unit)"
    }

}

private extension SubscriptionPeriod {

    var durationTitle: String {
        switch self.unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        default: return "Unknown"
        }
    }

    func periodTitle() -> String {
        let periodString = "\(self.value) \(self.durationTitle)"
        let pluralized = self.value > 1 ?  periodString + "s" : periodString
        return pluralized
    }

}

#endif
