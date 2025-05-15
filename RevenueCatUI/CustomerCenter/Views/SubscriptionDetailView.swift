//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionDetailView.swift
//
//  Created by Facundo Menzella on 14/5/25.

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SubscriptionDetailView: View {

    @Environment(\.openURL)
    private var openURL

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.navigationOptions)
    var navigationOptions

    @Environment(\.supportInformation)
    private var support

    @StateObject
    private var viewModel: SubscriptionDetailViewModel

    @Binding
    private var purchaseInformation: PurchaseInformation?

    @State
    private var showSimulatorAlert: Bool = false

    init(screen: CustomerCenterConfigData.Screen,
         purchaseInformation: Binding<PurchaseInformation?>,
         showPurchaseHistory: Bool,
         purchasesProvider: CustomerCenterPurchasesType,
         actionWrapper: CustomerCenterActionWrapper) {
        let viewModel = SubscriptionDetailViewModel(
            screen: screen,
            showPurchaseHistory: showPurchaseHistory,
            actionWrapper: actionWrapper,
            purchaseInformation: purchaseInformation.wrappedValue,
            purchasesProvider: purchasesProvider)

        self.init(
            purchaseInformation: purchaseInformation,
            viewModel: viewModel
        )
    }

    fileprivate init(
        purchaseInformation: Binding<PurchaseInformation?> = .constant(nil),
        viewModel: SubscriptionDetailViewModel
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
            .alert(isPresented: $showSimulatorAlert, content: {
                return Alert(
                    title: Text("Can't open URL"),
                    message: Text("There's no email app in the simulator"),
                    dismissButton: .default(Text("Ok")))
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

                Section {
                    if viewModel.showPurchaseHistory {
                        Button {
                            viewModel.showAllPurchases = true
                        } label: {
                            CompatibilityLabeledContent(localization[.seeAllPurchases]) {
                                Image(systemName: "chevron.forward")
                            }
                        }
                    }
                }

                Section {
                    ManageSubscriptionsButtonsView(viewModel: viewModel)
                }

                if let url = support?.supportURL(
                    localization: localization,
                    purchasesProvider: viewModel.purchasesProvider
                ), viewModel.shouldShowContactSupport,
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
                    ManageSubscriptionsButtonsView(viewModel: viewModel)
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
        .onChangeOf(purchaseInformation?.customerInfoRequestedDate) { _ in
            guard let purchase = purchaseInformation else { return }
            viewModel.reloadPurchaseInformation(purchase)
        }
    }

}

 #if DEBUG
 @available(iOS 15.0, *)
 @available(macOS, unavailable)
 @available(tvOS, unavailable)
 @available(watchOS, unavailable)
 struct SubscriptionDetailView_Previews: PreviewProvider {

    // swiftlint:disable force_unwrapping
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    viewModel: SubscriptionDetailViewModel(
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: false,
                        purchaseInformation: .monthlyRenewing
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Monthly renewing - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    viewModel: SubscriptionDetailViewModel(
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: false,
                        purchaseInformation: .yearlyExpiring()
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Yearly expiring - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    viewModel: SubscriptionDetailViewModel(
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: false,
                        purchaseInformation: .free
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Free subscription - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    viewModel: SubscriptionDetailViewModel(
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: false,
                        purchaseInformation: .consumable
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Consumable - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    viewModel: SubscriptionDetailViewModel(
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: false,
                        purchaseInformation: .yearlyExpiring(store: .playStore)
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Play Store - \(colorScheme)")
        }
        .environment(\.localization, CustomerCenterConfigData.default.localization)
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

 }

 #endif

#endif
