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
    private var managementURL: URL?

    @State
    private var purchaseInformation: PurchaseInformation

    @State
    private var showSimulatorAlert: Bool = false

    @State
    private var store: Store?

    @EnvironmentObject
    private var customerCenterViewModel: CustomerCenterViewModel

    private let screen: CustomerCenterConfigData.Screen?

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.supportInformation)
    private var supportInformation: CustomerCenterConfigData.Support?

    @Environment(\.openURL)
    private var openURL

    init(screen: CustomerCenterConfigData.Screen? = nil,
         purchaseInformation: PurchaseInformation) {
        self.screen = screen
        self._purchaseInformation = State(initialValue: purchaseInformation)
    }

    fileprivate init(store: Store,
                     managementURL: URL?,
                     purchaseInformation: PurchaseInformation,
                     screen: CustomerCenterConfigData.Screen) {
        self.screen = screen
        self._store = State(initialValue: store)
        self._managementURL = State(initialValue: managementURL)
        self._purchaseInformation = State(initialValue: purchaseInformation)
    }

    var body: some View {
        List {
            Section {
                SubscriptionDetailsView(purchaseInformation: purchaseInformation,
                                        refundRequestStatus: nil)
            }
            if let managementURL = self.managementURL {
                Section {
                    AsyncButton {
                        openURL(managementURL)
                    } label: {
                        Text(localization[.manageSubscription])
                    }
                }
            }

            if let url = supportInformation?.supportURL(localization: localization),
               URLUtilities.canOpenURL(url) || RuntimeUtils.isSimulator {
                Section {
                    AsyncButton {
                        if RuntimeUtils.isSimulator {
                            self.showSimulatorAlert = true
                        } else {
                            openURL(url)
                        }
                    } label: {
                        Text(localization[.contactSupport])
                    }
                }
            }
        }
        .dismissCircleButtonToolbarIfNeeded()
        .applyIfLet(screen, apply: { view, screen in
            view.navigationTitle(screen.title).navigationBarTitleDisplayMode(.inline)
        })
        .task {
            if store == nil {
                if let customerInfo = try? await Purchases.shared.customerInfo() {
                    self.managementURL = customerInfo.managementURL
                }
            }
        }
        .alert(isPresented: $showSimulatorAlert, content: {
            return Alert(
                title: Text("Can't open URL"),
                message: Text("There's no email app in the simulator"),
                dismissButton: .default(Text("Ok")))
        })
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
              displayName: "Web Billing"),
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

    // swiftlint:disable force_unwrapping
    static var previews: some View {
        Group {
            ForEach(previewCases, id: \.displayName) { data in
                WrongPlatformView(
                    store: data.store,
                    managementURL: data.managementURL,
                    purchaseInformation: getPurchaseInformation(for: data.customerInfo),
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!
                )
                .previewDisplayName(data.displayName)
            }
        }
    }

    private static func getPurchaseInformation(for customerInfo: CustomerInfo) -> PurchaseInformation {
        return PurchaseInformation(
            entitlement: customerInfo.entitlements.active.first!.value,
            transaction: customerInfo.subscriptionsByProductIdentifier.values.first!,
            customerInfoRequestedDate: customerInfo.requestDate)
    }

}

#endif

#endif
