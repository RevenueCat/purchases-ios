//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//
//  ManageSubscriptionViewModel.swift
//  RevenueCat
//
//  Created by Facundo Menzella on 3/5/25.
//

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionView: View {

    @Environment(\.openURL)
    private var openURL

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
    private var viewModel: ManageSubscriptionViewModel

    init(screen: CustomerCenterConfigData.Screen,
         purchaseInformation: PurchaseInformation?,
         purchasesProvider: CustomerCenterPurchasesType,
         actionWrapper: CustomerCenterActionWrapper) {
        let viewModel = ManageSubscriptionViewModel(
            screen: screen,
            actionWrapper: actionWrapper,
            purchaseInformation: purchaseInformation,
            purchasesProvider: purchasesProvider)
        self.init(viewModel: viewModel)
    }

    fileprivate init(viewModel: ManageSubscriptionViewModel) {
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
            .onOpenManageSubscriptionURL { productId in

            }

    }

    @ViewBuilder
    var content: some View {
        List {
            if let purchaseInformation = self.viewModel.purchaseInformation {
                SubscriptionDetailsView(
                    purchaseInformation: purchaseInformation,
                    refundRequestStatus: self.viewModel.refundRequestStatus
                )

                Section {
                    ManageSubscriptionsButtonsView(
                        relevantPathsForPurchase: self.viewModel.relevantPathsForPurchase,
                        determineFlowForPath: { path in
                            await self.viewModel.determineFlow(
                                for: path,
                                activeProductId: nil
                            )
                        },
                        label: { path in
                            if self.viewModel.loadingPath?.id == path.id {
                                TintedProgressView()
                            } else {
                                Text(path.title)
                            }
                        }
                    )
                    .disabled(self.viewModel.loadingPath != nil)
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
                    ManageSubscriptionsButtonsView(
                        relevantPathsForPurchase: self.viewModel.relevantPathsForPurchase,
                        determineFlowForPath: { path in
                            await self.viewModel.determineFlow(
                                for: path,
                                activeProductId: nil
                            )
                        },
                        label: { path in
                            if self.viewModel.loadingPath?.id == path.id {
                                TintedProgressView()
                            } else {
                                Text(path.title)
                            }
                        }
                    )
                    .disabled(self.viewModel.loadingPath != nil)
                }
            }
        }
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
 struct ManageSubscriptionView_Previews: PreviewProvider {

    // swiftlint:disable force_unwrapping
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            CompatibilityNavigationStack {
                let viewModelMonthlyRenewing = ManageSubscriptionViewModel(
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing,
                    refundRequestStatus: .success,
                    purchasesProvider: CustomerCenterPurchases()
                )
                ManageSubscriptionView(viewModel: viewModelMonthlyRenewing)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Monthly renewing - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionViewModel(
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationYearlyExpiring,
                    refundRequestStatus: .success,
                    purchasesProvider: CustomerCenterPurchases()
                )
                ManageSubscriptionView(viewModel: viewModelYearlyExpiring)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Yearly expiring - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionViewModel(
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationFree,
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionView(viewModel: viewModelYearlyExpiring)
                .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
                .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Free subscription - \(colorScheme)")

            CompatibilityNavigationStack {
                let viewModelYearlyExpiring = ManageSubscriptionViewModel(
                    screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
                    actionWrapper: CustomerCenterActionWrapper(),
                    purchaseInformation: CustomerCenterConfigTestData.consumable,
                    purchasesProvider: CustomerCenterPurchases())
                ManageSubscriptionView(viewModel: viewModelYearlyExpiring)
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
