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

@_spi(Internal) import RevenueCat
import StoreKit
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PromotionalOfferView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @State private var isLoading: Bool = false

    @StateObject
    private var viewModel: PromotionalOfferViewModel

    private let onDismissPromotionalOfferView: (PromotionalOfferViewAction) -> Void

    init(promotionalOffer: PromotionalOffer,
         product: StoreProduct,
         promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer,
         purchasesProvider: CustomerCenterPurchasesType,
         actionWrapper: CustomerCenterActionWrapper,
         onDismissPromotionalOfferView: @escaping (PromotionalOfferViewAction) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: PromotionalOfferViewModel(
            promotionalOfferData: PromotionalOfferData(
                promotionalOffer: promotionalOffer,
                product: product,
                promoOfferDetails: promoOfferDetails
            ),
            purchasesProvider: purchasesProvider,
            actionWrapper: actionWrapper
        ))
        self.onDismissPromotionalOfferView = onDismissPromotionalOfferView
    }

    private let horizontalPadding: CGFloat = 20

    var body: some View {
        ZStack {
            if let background = Color.from(colorInformation: appearance.backgroundColor, for: colorScheme) {
                background.edgesIgnoringSafeArea(.all)
            }

            VStack {
                if self.viewModel.error == nil {

                    AppIconView()
                        .padding(.top, 100)
                        .padding(.bottom)
                        .padding(.horizontal)

                    PromotionalOfferHeaderView(viewModel: self.viewModel)

                    Spacer()

                    PromoOfferButtonView(
                        isLoading: $isLoading,
                        viewModel: self.viewModel,
                        appearance: self.appearance
                    )
                    .padding(.horizontal, horizontalPadding)

                    Button {
                        self.dismissPromotionalOfferView(.declinePromotionalOffer)
                    } label: {
                        Text(self.localization[.noThanks])
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .applyIfLet(appearance.tintColor(colorScheme: colorScheme), apply: { $0.tint($1)})
        .onAppear {
            self.viewModel.onPromotionalOfferPurchaseFlowComplete = self.dismissPromotionalOfferView
        }
    }

    // Called when the promotional offer flow is purchased, successfully or not
    private func dismissPromotionalOfferView(
        _ action: PromotionalOfferViewAction
    ) {
        self.onDismissPromotionalOfferView(action) // Forward results to parent view
    }

    private struct AppIconView: View {

        var body: some View {
            if let appIcon = AppIconHelper.getAppIcon() {
                Image(uiImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(radius: 10)
            } else {
                Color.clear
                    // keep a size similar to what the image would have occuppied so layout looks correct
                    .frame(width: 70, height: 50)
            }
        }

    }

    private enum AppIconHelper {

        static func getAppIcon() -> UIImage? {
            guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                  let primaryIcons = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
                  let iconFiles = primaryIcons["CFBundleIconFiles"] as? [String],
                  let lastIcon = iconFiles.last else {
                return nil
            }
            return UIImage(named: lastIcon)
        }

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
    private let horizontalPadding: CGFloat = 40

    var body: some View {
        let textColor = Color.from(colorInformation: appearance.textColor, for: colorScheme)
        if let details = self.viewModel.promotionalOfferData?.promoOfferDetails {
            VStack(spacing: spacing) {
                Text(details.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top)

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
            .accessibilityIdentifier("promo-offer-primary-button")
            .buttonStyle(ProminentButtonStyle())
            .padding(.horizontal)
            .disabled(isLoading)
            .opacity(isLoading ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.3), value: isLoading)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// An enum representing the possible actions that a user can take on the PromotionalOfferView
enum PromotionalOfferViewAction {
    /// The user clicked the "No Thanks" button and declined the offer
    case declinePromotionalOffer

    /// The user successfully redeemed the promotional offer
    case successfullyRedeemedPromotionalOffer(PurchaseResultData)

    // Promotional code redemption failed. Either the user attempted to redeem the promotional offer, and it failed,
    // or the promotional offer was not loaded successfully.
    case promotionalCodeRedemptionFailed(Error)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PromotionalOfferViewAction {

    /// Whether the current path flow should be exited after the action is handled
    var shouldTerminateCurrentPathFlow: Bool {
        switch self {
        case .declinePromotionalOffer, .promotionalCodeRedemptionFailed:
            return false
        case .successfullyRedeemedPromotionalOffer:
            return true
        }
    }
}

#endif
