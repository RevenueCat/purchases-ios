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

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct PromotionalOfferView: View {

    @StateObject
    private var viewModel: PromotionalOfferViewModel
    @Environment(\.dismiss)
    private var dismiss

    init(promotionalOffer: PromotionalOffer,
         product: StoreProduct,
         promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer,
         localization: CustomerCenterConfigData.Localization) {
        let promotionalOfferData = PromotionalOfferData(promotionalOffer: promotionalOffer,
                                                        product: product,
                                                        promoOfferDetails: promoOfferDetails)
        let viewModel = PromotionalOfferViewModel(promotionalOfferData: promotionalOfferData,
                                                  localization: localization)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            if let details = self.viewModel.promotionalOfferData?.promoOfferDetails,
               let localization = self.viewModel.localization {
                Text(details.title)
                    .font(.title)
                    .padding()

                Text(details.subtitle)
                    .font(.title3)
                    .padding()

                Spacer()

                PromoOfferButtonView(viewModel: viewModel)

                let title = localization.commonLocalizedString(for: .noThanks) ?? "No, thanks"
                Button(title) {
                    dismiss()
                }
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct PromoOfferButtonView: View {

    @Environment(\.locale)
    private var locale

    @ObservedObject
    var viewModel: PromotionalOfferViewModel

    var body: some View {
        if let product = self.viewModel.promotionalOfferData?.product,
           let discount = self.viewModel.promotionalOfferData?.promotionalOffer.discount {
            let mainTitle = discount.localizedPricePerPeriodByPaymentMode(.current)
            let localizedProductPricePerPeriod = product.localizedPricePerPeriod(.current)

            Button(action: {
                Task {
                    await viewModel.purchasePromo()
                }
            }, label: {
                VStack {
                    Text(mainTitle)
                        .font(.headline)

                    let format = Localization.localizedBundle(self.locale)
                        .localizedString(forKey: "then_price_per_period", value: "then %@", table: nil)

                    Text(String(format: format, localizedProductPricePerPeriod))
                        .font(.subheadline)
                }
            })
            .buttonStyle(ManageSubscriptionsButtonStyle())
        }
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
