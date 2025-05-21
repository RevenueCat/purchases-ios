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

    @EnvironmentObject private var customerCenterViewModel: CustomerCenterViewModel

    @StateObject
    private var viewModel: SubscriptionDetailViewModel

    @State
    private var showSimulatorAlert: Bool = false

    init(screen: CustomerCenterConfigData.Screen,
         purchaseInformation: PurchaseInformation?,
         showPurchaseHistory: Bool,
         purchasesProvider: CustomerCenterPurchasesType,
         actionWrapper: CustomerCenterActionWrapper) {
        let viewModel = SubscriptionDetailViewModel(
            screen: screen,
            showPurchaseHistory: showPurchaseHistory,
            actionWrapper: actionWrapper,
            purchaseInformation: purchaseInformation,
            purchasesProvider: purchasesProvider)

        self.init(
            viewModel: viewModel
        )
    }

    fileprivate init(
        viewModel: SubscriptionDetailViewModel
    ) {
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
        ScrollViewWithOSBackground {
            LazyVStack(spacing: 0) {
                if let purchaseInformation = self.viewModel.purchaseInformation {
                    ScrollViewSection(title: sectionTitle) {
                        PurchaseInformationCardView(
                            purchaseInformation: purchaseInformation,
                            localization: localization,
                            refundStatus: viewModel.refundRequestStatus,
                            showChevron: false
                        )
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }

                    if viewModel.showPurchaseHistory {
                        seeAllSubscriptionsButton
                            .padding(.top, 16)
                    }

                } else {
                    let fallbackDescription = localization[.tryCheckRestore]

                    CompatibilityContentUnavailableView(
                        self.viewModel.screen.title,
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text(self.viewModel.screen.subtitle ?? fallbackDescription)
                    )
                    .padding()
                    .background(Color(colorScheme == .light
                                      ? UIColor.systemBackground
                                      : UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                ScrollViewSection(title: localization[.actionsSectionTitle]) {
                    ActiveSubscriptionButtonsView(viewModel: viewModel)
                        .padding(.top, 16)
                        .padding(.horizontal)
                }

                if let url = support?.supportURL(
                    localization: localization,
                    purchasesProvider: viewModel.purchasesProvider
                ), viewModel.shouldShowContactSupport,
                   URLUtilities.canOpenURL(url) || RuntimeUtils.isSimulator {
                    contactSupportView(url)
                        .padding(.top)
                }
            }
        }
        .overlay {
            RestorePurchasesAlert(
                isPresented: self.$viewModel.showRestoreAlert,
                actionWrapper: self.viewModel.actionWrapper
            )
            .environmentObject(customerCenterViewModel)
        }
        .applyIf(self.viewModel.screen.type == .management, apply: {
            $0.navigationTitle(self.viewModel.screen.title)
                .navigationBarTitleDisplayMode(.inline)
        })
    }

    @ViewBuilder
    func contactSupportView(_ url: URL) -> some View {
        AsyncButton {
            if RuntimeUtils.isSimulator {
                self.showSimulatorAlert = true
            } else {
                viewModel.inAppBrowserURL = IdentifiableURL(url: url)
            }
        } label: {
            CompatibilityLabeledContent(localization[.contactSupport])
                .padding(.horizontal)
                .padding(.vertical, 12)
        }
        .background(Color(colorScheme == .light
                          ? UIColor.systemBackground
                          : UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    private var seeAllSubscriptionsButton: some View {
        Button {
            viewModel.showAllPurchases = true
        } label: {
            CompatibilityLabeledContent(localization[.seeAllPurchases]) {
                Image(systemName: "chevron.forward")
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(colorScheme == .light
                              ? UIColor.systemBackground
                              : UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .tint(colorScheme == .dark ? .white : .black)
    }

    var sectionTitle: String {
        if viewModel.purchaseInformation?.expirationDate == nil
            && viewModel.purchaseInformation?.renewalDate == nil {
            return localization[.purchasesSectionTitle]
        } else {
            return localization[.subscriptionsSectionTitle]
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
                        showPurchaseHistory: true,
                        purchaseInformation: .yearlyExpiring(),
                        refundRequestStatus: .success
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
                        purchaseInformation: nil
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Emtpy state - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    viewModel: SubscriptionDetailViewModel(
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: true,
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
