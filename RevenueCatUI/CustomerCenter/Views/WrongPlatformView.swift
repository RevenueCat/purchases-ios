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
    private var subscriptionInformation: PurchaseInformation?

    private let screen: CustomerCenterConfigData.Screen?

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
        self.screen = nil
    }

    init(screen: CustomerCenterConfigData.Screen) {
        self.screen = screen
    }

    fileprivate init(store: Store,
                     managementURL: URL?,
                     subscriptionInformation: PurchaseInformation,
                     screen: CustomerCenterConfigData.Screen) {
        self.screen = screen
        self._store = State(initialValue: store)
        self._managementURL = State(initialValue: managementURL)
        self._subscriptionInformation = State(initialValue: subscriptionInformation)
    }

    var body: some View {
        List {
            if let subscriptionInformation = self.subscriptionInformation {
                Section {
                    SubscriptionDetailsView(purchaseInformation: subscriptionInformation,
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
        .applyIf(self.screen?.title != nil, apply: {
            $0.navigationTitle(self.screen!.title).navigationBarTitleDisplayMode(.inline)
        })
        .task {
            if store == nil {
                if let customerInfo = try? await Purchases.shared.customerInfo(),
                   let entitlement = customerInfo.entitlements.active.first?.value {
                    self.store = entitlement.store
                    self.managementURL = customerInfo.managementURL
                    self.subscriptionInformation = PurchaseInformation(entitlement: entitlement)
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

    private struct PreviewData {
        let store: Store
        let managementURL: URL?
        let customerInfo: CustomerInfo
        let displayName: String
    }

    private static let previewCases: [PreviewData] = [
        .init(store: .playStore,
              managementURL: URL(string: "https://play.google.com/store/account/subscriptions"),
              customerInfo: CustomerInfoFixtures.customerInfoWithGoogleSubscriptions,
              displayName: "Play Store"),
        .init(store: .rcBilling,
              managementURL: URL(string: "https://api.revenuecat.com/rcbilling/v1/customerportal/1234/portal"),
              customerInfo: CustomerInfoFixtures.customerInfoWithRCBillingSubscriptions,
              displayName: "RCBilling"),
        .init(store: .stripe,
              managementURL: nil,
              customerInfo: CustomerInfoFixtures.customerInfoWithStripeSubscriptions,
              displayName: "Stripe"),
        .init(store: .external,
              managementURL: nil,
              customerInfo: CustomerInfoFixtures.customerInfoWithStripeSubscriptions,
              displayName: "External"),
        .init(store: .promotional,
              managementURL: nil,
              customerInfo: CustomerInfoFixtures.customerInfoWithPromotional,
              displayName: "Promotional"),
        .init(store: .promotional,
              managementURL: nil,
              customerInfo: CustomerInfoFixtures.customerInfoWithLifetimePromotional,
              displayName: "Promotional Lifetime"),
        .init(store: .amazon,
              managementURL: nil,
              customerInfo: CustomerInfoFixtures.customerInfoWithAmazonSubscriptions,
              displayName: "Amazon")
    ]

    static var previews: some View {
        Group {
            ForEach(previewCases, id: \.displayName) { data in
                WrongPlatformView(
                    store: data.store,
                    managementURL: data.managementURL,
                    subscriptionInformation: getPurchaseInformation(for: data.customerInfo),
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!
                )
                .previewDisplayName(data.displayName)
            }
        }
    }

    private static func getPurchaseInformation(for customerInfo: CustomerInfo) -> PurchaseInformation {
        return PurchaseInformation(entitlement: customerInfo.entitlements.active.first!.value)
    }

}

#endif

#endif
