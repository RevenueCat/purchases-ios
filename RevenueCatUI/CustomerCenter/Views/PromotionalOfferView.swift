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
struct PromotionalOfferView: View {

    @StateObject
    private var viewModel: PromotionalOfferViewModel
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization
    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme)
    private var colorScheme
    @State private var isLoading: Bool = false

    init(promotionalOffer: PromotionalOffer,
         product: StoreProduct,
         promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer) {
        _viewModel = StateObject(wrappedValue: PromotionalOfferViewModel(
            promotionalOfferData: PromotionalOfferData(
                promotionalOffer: promotionalOffer,
                product: product,
                promoOfferDetails: promoOfferDetails
            )
        ))
    }

    private let horizontalPadding: CGFloat = 20

    var body: some View {
        ZStack {
            if let background = Color.from(colorInformation: appearance.backgroundColor, for: colorScheme) {
                background.edgesIgnoringSafeArea(.all)
            }

            VStack {
                if self.viewModel.error == nil {
                    PromotionalOfferHeaderView(viewModel: self.viewModel)

                    Spacer()

                    PromoOfferButtonView(isLoading: $isLoading,
                                         viewModel: self.viewModel,
                                         appearance: self.appearance)
                    .padding(.horizontal, horizontalPadding)

                    Button {
                        dismiss()
                    } label: {
                        Text(self.localization.commonLocalizedString(for: .noThanks))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    EmptyView()
                        .onAppear {
                            dismiss()
                        }
                }
            }
        }
        .onAppear {
            self.viewModel.onPromotionalOfferSuccessfullyPurchased = self.onPromotionalOfferSuccessfullyPurchased
        }
    }

    private func onPromotionalOfferSuccessfullyPurchased() {
        self.dismiss()
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PromotionalOfferHeaderView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme)
    private var colorScheme
    @ObservedObject
    private(set) var viewModel: PromotionalOfferViewModel

    private let spacing: CGFloat = 30
    private let topPadding: CGFloat = 150
    private let horizontalPadding: CGFloat = 40

    var body: some View {
        let textColor = Color.from(colorInformation: appearance.textColor, for: colorScheme)
        if let details = self.viewModel.promotionalOfferData?.promoOfferDetails {
            VStack(spacing: spacing) {
                Text(details.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top, topPadding)

                Text(details.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            .applyIf(textColor != nil, apply: { $0.foregroundColor(textColor) })
            .padding(.horizontal, horizontalPadding)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PromoOfferButtonView: View {

    @Binding var isLoading: Bool

    @Environment(\.locale)
    private var locale

    @ObservedObject
    private(set) var viewModel: PromotionalOfferViewModel

    private(set) var appearance: CustomerCenterConfigData.Appearance

    var body: some View {
        if let product = self.viewModel.promotionalOfferData?.product,
           let discount = self.viewModel.promotionalOfferData?.promotionalOffer.discount {
            let mainTitle = discount.localizedPricePerPeriodByPaymentMode(.current)
            let localizedProductPricePerPeriod = product.localizedPricePerPeriod(.current)

            AsyncButton {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = true
                }
                await viewModel.purchasePromo()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                }
            } label: {
                if isLoading {
                    TintedProgressView()
                } else {
                    VStack {
                        Text(mainTitle)
                            .font(.headline)

                        let format = Localization.localizedBundle(self.locale)
                            .localizedString(forKey: "then_price_per_period", value: "then %@", table: nil)

                        Text(String(format: format, localizedProductPricePerPeriod))
                            .font(.subheadline)
                    }
                }
            }
            .buttonStyle(ProminentButtonStyle())
            .padding(.horizontal)
            .disabled(isLoading)
            .opacity(isLoading ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.3), value: isLoading)
        }
    }

}

#endif
