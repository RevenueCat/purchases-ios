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

    init(screen: CustomerCenterConfigData.Screen,
         purchaseInformation: PurchaseInformation?,
         purchasesProvider: CustomerCenterPurchasesType,
         actionWrapper: CustomerCenterActionWrapper) {
        let viewModel = ManageSubscriptionsViewModel(
            screen: screen,
            actionWrapper: actionWrapper,
            purchaseInformation: purchaseInformation,
            purchasesProvider: purchasesProvider)
        self.init(viewModel: viewModel)
    }

    fileprivate init(viewModel: ManageSubscriptionsViewModel) {
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
                isPresented: $viewModel.showPurchases,
                usesNavigationStack: navigationOptions.usesNavigationStack
            ) {
                PurchaseHistoryView(viewModel:
                                        PurchaseHistoryViewModel(purchasesProvider: self.viewModel.purchasesProvider)
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
                        viewModel.showPurchases = true
                    } label: {
                        Text(localization[.seeAllPurchases])
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
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
    }

}

#if DEBUG
 @available(iOS 15.0, *)
 @available(macOS, unavailable)
 @available(tvOS, unavailable)
 @available(watchOS, unavailable)
 struct ManageSubscriptionsView_Previews: PreviewProvider {

    // swiftlint:disable force_unwrapping
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            CompatibilityNavigationStack {
                let viewModelMonthlyRenewing = ManageSubscriptionsViewModel(
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing,
                    refundRequestStatus: .success,
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(viewModel: viewModelMonthlyRenewing)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Monthly renewing - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionsViewModel(
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationYearlyExpiring,
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(viewModel: viewModelYearlyExpiring)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Yearly expiring - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionsViewModel(
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationFree,
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(viewModel: viewModelYearlyExpiring)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Free subscription - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionsViewModel(
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.consumable,
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionsView(viewModel: viewModelYearlyExpiring)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Consumable - \(colorScheme)")
        }
    }

 }

#endif

#endif
