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

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.supportInformation)
    private var support

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.navigationOptions)
    var navigationOptions

    @StateObject
    private var viewModel: ManageSubscriptionsViewModel

    @Binding
    var purchaseInformation: PurchaseInformation?

    init(screen: CustomerCenterConfigData.Screen,
         purchaseInformation: Binding<PurchaseInformation?>,
         purchasesProvider: CustomerCenterPurchasesType,
         actionWrapper: CustomerCenterActionWrapper) {
        self.init(
            purchaseInformation: purchaseInformation,
            viewModel: ManageSubscriptionsViewModel(
            screen: screen,
            actionWrapper: actionWrapper,
            purchaseInformation: purchaseInformation.wrappedValue,
            purchasesProvider: purchasesProvider))
    }

    fileprivate init(
        purchaseInformation: Binding<PurchaseInformation?>,
        viewModel: ManageSubscriptionsViewModel
    ) {
        self._purchaseInformation = purchaseInformation
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .compatibleNavigation(
                item: $viewModel.feedbackSurveyData,
                usesNavigationStack: navigationOptions.usesNavigationStack
            ) { feedbackSurveyData in
                FeedbackSurveyView(
                    feedbackSurveyData: feedbackSurveyData,
                    purchasesProvider: self.viewModel.purchasesProvider,
                    actionWrapper: self.viewModel.actionWrapper,
                    isPresented: .isNotNil(self.$viewModel.feedbackSurveyData))
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
                .environment(\.navigationOptions, navigationOptions)
            }
            .compatibleNavigation(
                isPresented: $viewModel.showAllPurchases,
                usesNavigationStack: navigationOptions.usesNavigationStack
            ) {
                PurchaseHistoryView(
                    viewModel: PurchaseHistoryViewModel(purchasesProvider: self.viewModel.purchasesProvider)
                )
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
                .environment(\.navigationOptions, navigationOptions)
            }
            .sheet(item: self.$viewModel.promotionalOfferData) { promotionalOfferData in
                PromotionalOfferView(
                    promotionalOffer: promotionalOfferData.promotionalOffer,
                    product: promotionalOfferData.product,
                    promoOfferDetails: promotionalOfferData.promoOfferDetails,
                    purchasesProvider: self.viewModel.purchasesProvider,
                    onDismissPromotionalOfferView: { userAction in
                        Task(priority: .userInitiated) {
                            await self.viewModel.handleDismissPromotionalOfferView(userAction)
                        }
                    }
                )
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
                .interactiveDismissDisabled()
            }
            .sheet(item: self.$viewModel.inAppBrowserURL,
                   onDismiss: {
                self.viewModel.onDismissInAppBrowser()
            }, content: { inAppBrowserURL in
                SafariView(url: inAppBrowserURL.url)
            })

    }

    @ViewBuilder
    var content: some View {
        List {
            if let purchaseInformation = self.viewModel.purchaseInformation {
                SubscriptionDetailsView(
                    purchaseInformation: purchaseInformation,
                    refundRequestStatus: self.viewModel.refundRequestStatus
                )

                if support?.displayPurchaseHistoryLink == true {
                    Button {
                        viewModel.showAllPurchases = true
                    } label: {
                        CompatibilityLabeledContent {
                            Text(localization[.seeAllPurchases])
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        } content: {
                            Image(systemName: "chevron.forward")
                        }
                    }
                }

                Section {
                    ManageSubscriptionsButtonsView(
                        viewModel: self.viewModel
                    )
                } header: {
                    if let subtitle = self.viewModel.screen.subtitle {
                        Text(subtitle)
                            .textCase(nil)
                    }
                }
            } else {
                let fallbackDescription = localization[.tryCheckRestore]

                Section {
                    CompatibilityContentUnavailableView(
                        self.viewModel.screen.title,
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text(self.viewModel.screen.subtitle ?? fallbackDescription)
                    )
                }

                Section {
                    ManageSubscriptionsButtonsView(viewModel: self.viewModel)
                }
            }
        }
        .dismissCircleButtonToolbarIfNeeded()
        .overlay {
            RestorePurchasesAlert(
                isPresented: self.$viewModel.showRestoreAlert,
                actionWrapper: self.viewModel.actionWrapper
            )
        }
        .applyIf(self.viewModel.screen.type == .management, apply: {
            $0.navigationTitle(self.viewModel.screen.title)
                .navigationBarTitleDisplayMode(.inline)
         })
        .onChangeOf(purchaseInformation?.customerInfoRequestedDate) { _ in
            guard let purchase = purchaseInformation else { return }
            viewModel.reloadPurchaseInformation(purchase)
        }
    }

}

#if DEBUG
// swiftlint:disable force_unwrapping
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsView_Previews: PreviewProvider {

     static let managementScreen: CustomerCenterConfigData.Screen = CustomerCenterConfigTestData
         .customerCenterData()
         .screens[.management]!

    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            CompatibilityNavigationStack {
                let viewModelMonthlyRenewing = ManageSubscriptionsViewModel(
                    screen: Self.managementScreen,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing(),
                    purchasesProvider: CustomerCenterPurchases())

                ManageSubscriptionsView(
                    purchaseInformation: .constant(nil),
                    viewModel: viewModelMonthlyRenewing
                )
                    .environment(\.localization, CustomerCenterConfigTestData.customerCenterData().localization)
                    .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData().appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Renewing subscription - No refund - No discount - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelMonthlyRenewing = ManageSubscriptionsViewModel(
                    screen: Self.managementScreen,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing(
                        introductoryDiscount: CustomerCenterConfigTestData.discount(paymentMode: .payAsYouGo)
                    ),
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(
                    purchaseInformation: .constant(nil),
                    viewModel: viewModelMonthlyRenewing
                )
                    .environment(\.localization, CustomerCenterConfigTestData.customerCenterData().localization)
                    .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData().appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Renewing subscription - No refund - Pay as you go - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelMonthlyRenewing = ManageSubscriptionsViewModel(
                    screen: Self.managementScreen,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing(
                        introductoryDiscount: CustomerCenterConfigTestData.discount(
                            paymentMode: .payUpFront,
                            price: 2.99,
                            subscriptionPeriod: .init(value: 3, unit: .month)
                        )
                    ),
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(
                    purchaseInformation: .constant(nil),
                    viewModel: viewModelMonthlyRenewing
                )
                    .environment(\.localization, CustomerCenterConfigTestData.customerCenterData().localization)
                    .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData().appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Renewing subscription - No refund - Pay up front - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelMonthlyRenewing = ManageSubscriptionsViewModel(
                    screen: Self.managementScreen,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing(
                        introductoryDiscount: CustomerCenterConfigTestData.discount(
                            paymentMode: .freeTrial,
                            price: 2.99,
                            subscriptionPeriod: .init(value: 3, unit: .month)
                        )
                    ),
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(
                    purchaseInformation: .constant(nil),
                    viewModel: viewModelMonthlyRenewing
                )
                    .environment(\.localization, CustomerCenterConfigTestData.customerCenterData().localization)
                    .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData().appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Renewing subscription - No refund - Free trial - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelMonthlyRenewing = ManageSubscriptionsViewModel(
                    screen: Self.managementScreen,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing(),
                    refundRequestStatus: .success,
                    purchasesProvider: CustomerCenterPurchases())

                ManageSubscriptionsView(
                    purchaseInformation: .constant(nil),
                    viewModel: viewModelMonthlyRenewing
                )
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData().localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData().appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Renewing subscription - Requested refund - No discount - \(colorScheme)")
//
            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionsViewModel(
                    screen: Self.managementScreen,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationYearlyExpiring(),
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(
                    purchaseInformation: .constant(nil),
                    viewModel: viewModelYearlyExpiring)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData().localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData().appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Cancelled subscription - No refund - No discount - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionsViewModel(
                    screen: Self.managementScreen,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationFree,
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(
                    purchaseInformation: .constant(nil),
                    viewModel: viewModelYearlyExpiring)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData().localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData().appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Free subscription - No refund - No discount - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionsViewModel(
                    screen: Self.managementScreen,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.consumable,
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(
                    purchaseInformation: .constant(nil),
                    viewModel: viewModelYearlyExpiring)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData().localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData().appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Consumable - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionsViewModel(
                    screen: Self.managementScreen,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.consumable,
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(
                    purchaseInformation: .constant(nil),
                    viewModel: viewModelYearlyExpiring
                )
                    .environment(\.localization, CustomerCenterConfigTestData.customerCenterData().localization)
                    .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData().appearance)
                    .environment(\.supportInformation, CustomerCenterConfigTestData.customerCenterData(
                        displayPurchaseHistoryLink: true,
                    ).support)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("See all purchases - \(colorScheme)")
        }
    }

}

 #endif

#endif
