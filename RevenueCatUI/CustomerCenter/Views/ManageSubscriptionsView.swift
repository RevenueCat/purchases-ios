//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization
    @Environment(\.colorScheme)
    private var colorScheme

    @StateObject
    private var viewModel: ManageSubscriptionsViewModel

    private let customerCenterActionHandler: CustomerCenterActionHandler?

    init(screen: CustomerCenterConfigData.Screen,
         purchaseInformation: PurchaseInformation?,
         customerCenterActionHandler: CustomerCenterActionHandler?) {
        let viewModel = ManageSubscriptionsViewModel(
            screen: screen,
            customerCenterActionHandler: customerCenterActionHandler,
            purchaseInformation: purchaseInformation)
        self.init(viewModel: viewModel, customerCenterActionHandler: customerCenterActionHandler)
    }

    fileprivate init(viewModel: ManageSubscriptionsViewModel,
                     customerCenterActionHandler: CustomerCenterActionHandler?) {
        self._viewModel = .init(wrappedValue: viewModel)
        self.customerCenterActionHandler = customerCenterActionHandler
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            content
                .navigationDestination(isPresented: .isNotNil(self.$viewModel.feedbackSurveyData)) {
                    if let feedbackSurveyData = self.viewModel.feedbackSurveyData {
                        FeedbackSurveyView(feedbackSurveyData: feedbackSurveyData,
                                           customerCenterActionHandler: self.customerCenterActionHandler,
                                           isPresented: .isNotNil(self.$viewModel.feedbackSurveyData))
                    }
                }
        } else {
            content
                .background(NavigationLink(
                    destination: self.viewModel.feedbackSurveyData.map { data in
                        FeedbackSurveyView(feedbackSurveyData: data,
                                           customerCenterActionHandler: self.customerCenterActionHandler,
                                           isPresented: .isNotNil(self.$viewModel.feedbackSurveyData))
                    },
                    isActive: .isNotNil(self.$viewModel.feedbackSurveyData)
                ) {
                    EmptyView()
                })
        }
    }

    @ViewBuilder
    var content: some View {
        ZStack {
            List {

                if let purchaseInformation = self.viewModel.purchaseInformation {
                    Section {
                        SubscriptionDetailsView(
                            purchaseInformation: purchaseInformation,
                            refundRequestStatus: self.viewModel.refundRequestStatus)
                    }
                    Section {
                        ManageSubscriptionsButtonsView(viewModel: self.viewModel,
                                                       loadingPath: self.$viewModel.loadingPath)
                    } header: {
                        if let subtitle = self.viewModel.screen.subtitle {
                            Text(subtitle)
                                .textCase(nil)
                        }
                    }
                } else {
                    let fallbackDescription = localization.commonLocalizedString(for: .tryCheckRestore)

                    Section {
                        CompatibilityContentUnavailableView(
                            self.viewModel.screen.title,
                            systemImage: "exclamationmark.triangle.fill",
                            description: Text(self.viewModel.screen.subtitle ?? fallbackDescription)
                        )
                    }

                    Section {
                        ManageSubscriptionsButtonsView(viewModel: self.viewModel,
                                                       loadingPath: self.$viewModel.loadingPath)
                    }
                }

            }
        }
        .toolbar {
            ToolbarItem(placement: .compatibleTopBarTrailing) {
                DismissCircleButton()
            }
        }
        .restorePurchasesAlert(isPresented: self.$viewModel.showRestoreAlert)
        .sheet(
            item: self.$viewModel.promotionalOfferData,
            content: { promotionalOfferData in
                PromotionalOfferView(
                    promotionalOffer: promotionalOfferData.promotionalOffer,
                    product: promotionalOfferData.product,
                    promoOfferDetails: promotionalOfferData.promoOfferDetails,
                    onDismissPromotionalOfferView: { userAction in
                        Task(priority: .userInitiated) {
                            await self.viewModel.handleDismissPromotionalOfferView(userAction)
                        }
                    }
                )
                .interactiveDismissDisabled()
            })
        .sheet(item: self.$viewModel.inAppBrowserURL,
               onDismiss: {
            self.viewModel.onDismissInAppBrowser()
        }, content: { inAppBrowserURL in
            SafariView(url: inAppBrowserURL.url)
        })
        .applyIf(self.viewModel.screen.type == .management, apply: {
            $0.navigationTitle(self.viewModel.screen.title).navigationBarTitleDisplayMode(.inline)
        })

    }

}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            CompatibilityNavigationStack {
                let viewModelMonthlyRenewing = ManageSubscriptionsViewModel(
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
                    customerCenterActionHandler: nil,
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing,
                    refundRequestStatus: .success)
                ManageSubscriptionsView(viewModel: viewModelMonthlyRenewing,
                                        customerCenterActionHandler: nil)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)
            }.preferredColorScheme(colorScheme)
            .previewDisplayName("Monthly renewing - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionsViewModel(
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
                    customerCenterActionHandler: nil,
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationYearlyExpiring)
                ManageSubscriptionsView(viewModel: viewModelYearlyExpiring,
                                        customerCenterActionHandler: nil)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)
            }.preferredColorScheme(colorScheme)
            .previewDisplayName("Yearly expiring - \(colorScheme)")
        }
    }

}

#endif

#endif
