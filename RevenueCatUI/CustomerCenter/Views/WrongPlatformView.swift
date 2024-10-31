//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WrongPlatformView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import Foundation
import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct WrongPlatformView: View {

    @State
    private var store: Store?
    @State
    private var managementURL: URL?
    @State
    private var subscriptionInformation: SubscriptionInformation?

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization
    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme)
    private var colorScheme
    @Environment(\.supportInformation)
    private var supportInformation: CustomerCenterConfigData.Support?
    @Environment(\.openURL)
    private var openURL

    private var supportURL: URL? {
        guard let supportInformation = self.supportInformation else { return nil }
        let subject = self.localization.commonLocalizedString(for: .defaultSubject)
        let body = supportInformation.calculateBody(self.localization)
        return URLUtilities.createMailURLIfPossible(email: supportInformation.email,
                                                    subject: subject,
                                                    body: body)
    }

    init() {
    }

    fileprivate init(store: Store,
                     managementURL: URL?,
                     subscriptionInformation: SubscriptionInformation) {
        self._store = State(initialValue: store)
        self._managementURL = State(initialValue: managementURL)
        self._subscriptionInformation = State(initialValue: subscriptionInformation)
    }

    var body: some View {
        List {
            if let subscriptionInformation = self.subscriptionInformation {
                Section {
                    SubscriptionDetailsView(subscriptionInformation: subscriptionInformation,
                                            refundRequestStatus: nil)
                }
            }
            if let managementURL = self.managementURL {
                Section {
                    AsyncButton {
                        openURL(managementURL)
                    } label: {
                        Text(localization.commonLocalizedString(for: .manageSubscription))
                    }
                }
            }
            if let url = supportURL {
                Section {
                    AsyncButton {
                        openURL(url)
                    } label: {
                        Text(localization.commonLocalizedString(for: .contactSupport))
                    }
                }
            }

        }
        .toolbar {
            ToolbarItem(placement: .compatibleTopBarTrailing) {
                DismissCircleButton()
            }
        }
        .navigationTitle("How can we help?")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if store == nil {
                if let customerInfo = try? await Purchases.shared.customerInfo(),
                   let entitlement = customerInfo.entitlements.active.first?.value {
                    self.store = entitlement.store
                    self.managementURL = customerInfo.managementURL
                    self.subscriptionInformation = SubscriptionInformation(entitlement: entitlement)
                }
            }
        }
    }

    private func humanReadableInstructions(for store: Store?) -> String {
        let defaultContactSupport = localization.commonLocalizedString(for: .pleaseContactSupportToManage)

        if let store {
            switch store {
            case .appStore, .macAppStore:
                return localization.commonLocalizedString(for: .appleSubscriptionManage)
            case .playStore:
                return localization.commonLocalizedString(for: .googleSubscriptionManage)
            case .stripe, .rcBilling:
                return localization.commonLocalizedString(for: .webSubscriptionManage)
            case .external, .promotional, .unknownStore:
                return defaultContactSupport
            case .amazon:
                return localization.commonLocalizedString(for: .amazonSubscriptionManage)
            @unknown default:
                return defaultContactSupport
            }
        } else {
            return defaultContactSupport
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct WrongPlatformView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            WrongPlatformView(store: .playStore,
                              managementURL: URL(string: "https://play.google.com/store/account/subscriptions"),
                              subscriptionInformation: getSubscriptionInformation(for: CustomerInfoFixtures.customerInfoWithGoogleSubscriptions))
                .previewDisplayName("Play Store")

            WrongPlatformView(store: .rcBilling,
                              managementURL:
                                URL(string: "https://api.revenuecat.com/rcbilling/v1/customerportal/1234/portal"),
                              subscriptionInformation: getSubscriptionInformation(for: CustomerInfoFixtures.customerInfoWithStripeSubscriptions))
                .previewDisplayName("RCBilling")

            WrongPlatformView(store: .stripe,
                              managementURL: nil,
                              subscriptionInformation: getSubscriptionInformation(for: CustomerInfoFixtures.customerInfoWithStripeSubscriptions))
                .previewDisplayName("Stripe")

            WrongPlatformView(store: .external,
                              managementURL: nil,
                              subscriptionInformation: getSubscriptionInformation(for: CustomerInfoFixtures.customerInfoWithStripeSubscriptions))
                .previewDisplayName("External")

            WrongPlatformView(store: .promotional,
                              managementURL: nil,
                              subscriptionInformation: getSubscriptionInformation(for: CustomerInfoFixtures.customerInfoWithPromotional))
                .previewDisplayName("Promotional")

            WrongPlatformView(store: .promotional,
                              managementURL: nil,
                              subscriptionInformation: getSubscriptionInformation(for: CustomerInfoFixtures.customerInfoWithLifetimePromotional))
                .previewDisplayName("Promotional Lifetime")

            WrongPlatformView(store: .amazon,
                              managementURL: nil,
                              subscriptionInformation: getSubscriptionInformation(for: CustomerInfoFixtures.customerInfoWithAmazonSubscriptions))
                .previewDisplayName("Amazon")

        }

    }

    private static func getSubscriptionInformation(for customerInfo: CustomerInfo) -> SubscriptionInformation {
        return SubscriptionInformation(entitlement: customerInfo.entitlements.active.first!.value)
    }

}

#endif

#endif
