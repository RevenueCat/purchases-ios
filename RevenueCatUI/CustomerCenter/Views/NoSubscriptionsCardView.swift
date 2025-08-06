//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NoSubscriptionsCardView.swift
//
//  Created by Facundo Menzella on 26/5/25.

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsCardView: View {

    @Environment(\.colorScheme)
    private var colorScheme

    @State
    private var offering: Offering?

    @State
    private var showOffering = false

    @State
    private var isLoadingOffering = true

    private let title: String
    private let subtitle: String
    private let buySubscriptionTitle: String
    private let offeringId: String?

    private let purchasesProvider: CustomerCenterPurchasesType

    init(
        title: String,
        subtitle: String,
        buySubscriptionTitle: String,
        offeringId: String?,
        purchasesProvider: CustomerCenterPurchasesType = MockCustomerCenterPurchases()
    ) {
        self.title = title
        self.subtitle = subtitle
        self.buySubscriptionTitle = buySubscriptionTitle
        self.offeringId = offeringId
        self.purchasesProvider = purchasesProvider
    }

    init(
        offeringId: String?,
        localization: CustomerCenterConfigData.Localization,
        purchasesProvider: CustomerCenterPurchasesType
    ) {
        self.init(
            title: localization[.noSubscriptionsFound],
            subtitle: localization[.tryCheckRestore],
            buySubscriptionTitle: localization[.buySubscription],
            offeringId: offeringId,
            purchasesProvider: purchasesProvider
        )
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(alignment: .center)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
                .frame(alignment: .leading)
                .multilineTextAlignment(.center)

            if offering != nil || isLoadingOffering {
                Button(buySubscriptionTitle) {
                    self.showOffering = true
                }
                .buttonStyle(BuySubscriptionButtonStyle())
                .disabled(isLoadingOffering)
                .padding(.top)
                .opacity(isLoadingOffering ? 0 : 1.0)
                .overlay(content: {
                    if isLoadingOffering {
                        TintedProgressView()
                    }
                })
            }
        }
        .padding(16)
        .background(Color(colorScheme == .light
                          ? UIColor.systemBackground
                          : UIColor.secondarySystemBackground))
        .animation(.easeInOut(duration: 0.3), value: isLoadingOffering)
        .sheet(isPresented: $showOffering, content: {
            PaywallView(
                configuration: .init(
                    offering: offering,
                    displayCloseButton: false
                )
            )
        })
        .task(priority: .userInitiated) {
            await refreshOffering()
        }
    }

    private func refreshOffering() async {
        guard let offeringId else {
            isLoadingOffering = false
            return
        }

        isLoadingOffering = true
        defer { isLoadingOffering = false }

        do {
            let offerings = try await purchasesProvider.offerings()
            if offeringId == "current" {
                self.offering = offerings.current
            } else {
                self.offering = offerings.offering(identifier: offeringId)
            }
        } catch {
            Logger.debug("Error fetching offerings: \(error)")
            self.offering = nil
        }
    }
}

private extension PurchaseInformation {
    var shoulShowPricePaid: Bool {
        renewalPrice != nil || expirationDate != nil
    }
}

private extension RefundRequestStatus {

    var icon: Image? {
        switch self {
        case .error:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .success:
            return Image(systemName: "info.circle.fill")
        case .userCancelled:
            return nil
        @unknown default:
            return nil
        }
    }

    func subtitle(
        localization: CustomerCenterConfigData.Localization
    ) -> String? {
        switch self {
        case .error:
            return localization[.refundErrorGeneric]
        case .success:
            return localization[.refundSuccess]
        case .userCancelled:
            return nil
        @unknown default:
            return nil
        }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct BuySubscriptionButtonStyle: ButtonStyle {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed
                ? tintColor?.opacity(0.8)
                : tintColor
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }

    private var tintColor: Color? {
        Color.from(colorInformation: appearance.accentColor, for: self.colorScheme)
    }
}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsCardView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            ScrollViewWithOSBackground {
                NoSubscriptionsCardView(
                    offeringId: "offeringId",
                    localization: CustomerCenterConfigData.default.localization,
                    purchasesProvider: MockCustomerCenterPurchases()
                )
                .cornerRadius(10)
                .padding([.leading, .trailing])
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("NoSubscriptionsCardView - Paywall")

            ScrollViewWithOSBackground {
                NoSubscriptionsCardView(
                    offeringId: nil,
                    localization: CustomerCenterConfigData.default.localization,
                    purchasesProvider: MockCustomerCenterPurchases()
                )
                .cornerRadius(10)
                .padding([.leading, .trailing])
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("NoSubscriptionsCardView - No Paywall")
        }
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

}

#endif

#endif
