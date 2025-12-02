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

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
// swiftlint:disable file_length
struct SubscriptionDetailView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @Environment(\.navigationOptions)
    var navigationOptions

    @Environment(\.openURL)
    var openURL

    @Environment(\.supportInformation)
    private var support

    @StateObject
    private var viewModel: SubscriptionDetailViewModel

    @ObservedObject
    private var customerInfoViewModel: CustomerCenterViewModel

    @State
    private var showSimulatorAlert: Bool = false

    init(
        customerInfoViewModel: CustomerCenterViewModel,
        screen: CustomerCenterConfigData.Screen,
        purchaseInformation: PurchaseInformation?,
        showPurchaseHistory: Bool,
        showVirtualCurrencies: Bool,
        allowsMissingPurchaseAction: Bool,
        purchasesProvider: CustomerCenterPurchasesType,
        actionWrapper: CustomerCenterActionWrapper) {
            let viewModel = SubscriptionDetailViewModel(
                customerInfoViewModel: customerInfoViewModel,
                screen: screen,
                showPurchaseHistory: showPurchaseHistory,
                showVirtualCurrencies: showVirtualCurrencies,
                allowsMissingPurchaseAction: allowsMissingPurchaseAction,
                actionWrapper: actionWrapper,
                purchaseInformation: purchaseInformation,
                purchasesProvider: purchasesProvider)

            self.init(
                customerInfoViewModel: customerInfoViewModel,
                viewModel: viewModel
            )
        }

    fileprivate init(
        customerInfoViewModel: CustomerCenterViewModel,
        viewModel: SubscriptionDetailViewModel
    ) {
        self.customerInfoViewModel = customerInfoViewModel
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        content
        // This is needed because `CustomerCenterViewModel` is isolated to @MainActor
        // A bigger refactor is needed, but its already throwing a warning.
            .modifier(self.customerInfoViewModel.purchasesProvider
                .manageSubscriptionsSheetViewModifier(isPresented: .init(
                    get: { customerInfoViewModel.manageSubscriptionsSheet },
                    set: { manage in DispatchQueue.main.async {
                        customerInfoViewModel.manageSubscriptionsSheet = manage
                    }}
                ), subscriptionGroupID: viewModel.purchaseInformation?.subscriptionGroupID
                )
            )
            .modifier(self.customerInfoViewModel.purchasesProvider
                .changePlansSheetViewModifier(
                    isPresented: .init(
                        get: { customerInfoViewModel.changePlansSheet },
                        set: { manage in DispatchQueue.main.async {
                            customerInfoViewModel.changePlansSheet = manage
                        }}
                    ),
                    subscriptionGroupID: viewModel.purchaseSubscriptionGroupID,
                    productIDs: viewModel.changePlanProductIDs
                )
            )
            .onAppear { viewModel.didAppear() }
            .onChangeOf(customerInfoViewModel.manageSubscriptionsSheet) { manageSubscriptionsSheet in
                if !manageSubscriptionsSheet {
                    viewModel.refreshPurchase()
                }
            }
            .onChangeOf(customerInfoViewModel.changePlansSheet) { changePlansSheet in
                if !changePlansSheet {
                    viewModel.refreshPurchase()
                }
            }
            .compatibleNavigation(
                isPresented: $viewModel.showAllPurchases,
                usesNavigationStack: navigationOptions.usesNavigationStack
            ) {
                PurchaseHistoryView(
                    viewModel: PurchaseHistoryViewModel(
                        purchasesProvider: self.viewModel.purchasesProvider,
                        localization: localization
                    )
                )
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
                .environment(\.navigationOptions, navigationOptions)
            }
            .compatibleNavigation(
                isPresented: $viewModel.showAllInAppCurrenciesScreen,
                usesNavigationStack: navigationOptions.usesNavigationStack
            ) {
                VirtualCurrencyBalancesScreen(
                    viewModel: VirtualCurrencyBalancesScreenViewModel(
                        purchasesProvider: self.viewModel.purchasesProvider
                    )
                )
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
                .environment(\.navigationOptions, navigationOptions)
            }
            .sheet(isPresented: .isNotNil(self.$viewModel.feedbackSurveyData)) {
                if let feedback = viewModel.feedbackSurveyData {
                    FeedbackSurveyView(
                        feedbackSurveyData: feedback,
                        purchasesProvider: self.viewModel.purchasesProvider,
                        actionWrapper: self.viewModel.actionWrapper,
                        isPresented: .isNotNil(self.$viewModel.feedbackSurveyData))
                    .environment(\.appearance, appearance)
                    .environment(\.localization, localization)
                    .environment(\.navigationOptions, navigationOptions)
                }
            }
            .sheet(item: self.$viewModel.inAppBrowserURL,
                   onDismiss: {
                self.viewModel.onDismissInAppBrowser()
            }, content: { inAppBrowserURL in
                SafariView(url: inAppBrowserURL.url)
            })
            .sheet(
                item: $viewModel.promotionalOfferData
            ) { promotionalOfferData in
                PromotionalOfferView(
                    promotionalOffer: promotionalOfferData.promotionalOffer,
                    product: promotionalOfferData.product,
                    promoOfferDetails: promotionalOfferData.promoOfferDetails,
                    purchasesProvider: self.viewModel.purchasesProvider,
                    actionWrapper: self.viewModel.actionWrapper,
                    onDismissPromotionalOfferView: { action in
                        viewModel.onDismissPromotionalOffer(action: action)
                    }
                )
                .interactiveDismissDisabled()
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
            }
            .sheet(isPresented: $viewModel.showCreateTicket) {
                CreateTicketView(
                    isPresented: $viewModel.showCreateTicket,
                    purchasesProvider: self.viewModel.purchasesProvider
                )
                .environment(\.appearance, appearance)
                .environment(\.localization, localization)
                .environment(\.navigationOptions, navigationOptions)
            }
            .alert(isPresented: $showSimulatorAlert, content: {
                return Alert(
                    title: Text("Can't open URL"),
                    message: Text("There's no email app in the simulator"),
                    dismissButton: .default(Text("Ok")))
            })
    }

}

@available(iOS 15.0, *)
private extension SubscriptionDetailView {

    @ViewBuilder
    var content: some View {
        ScrollViewWithOSBackground {
            LazyVStack(spacing: 0) {
                if viewModel.isRefreshing {
                    ProgressView()
                        .padding(.vertical)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isRefreshing)
                }

                if !customerInfoViewModel.hasAnyPurchases {
                    NoSubscriptionsCardView(
                        screenOffering: viewModel.screen.offering,
                        screen: viewModel.screen,
                        localization: localization,
                        purchasesProvider: viewModel.purchasesProvider
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 32)
                } else {
                    if let purchaseInformation = self.viewModel.purchaseInformation {
                        PurchaseInformationCardView(
                            purchaseInformation: purchaseInformation,
                            localization: localization,
                            accessibilityIdentifier: "0",
                            refundStatus: viewModel.refundRequestStatus,
                            showChevron: false
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 32)
                    }

                    if let virtualCurrencies = customerInfoViewModel.virtualCurrencies,
                       !virtualCurrencies.all.isEmpty,
                       viewModel.showVirtualCurrencies {
                        VirtualCurrenciesScrollViewWithOSBackgroundSection(
                            virtualCurrencies: virtualCurrencies,
                            onSeeAllInAppCurrenciesButtonTapped: self.viewModel.displayAllInAppCurrenciesScreen
                        )
                        Spacer().frame(height: 32)
                    }
                }

                ActiveSubscriptionButtonsView(viewModel: viewModel)
                    .padding(.horizontal)

                if viewModel.showPurchaseHistory {
                    seeAllSubscriptionsButton
                        .padding(.vertical, 16)
                }

                if viewModel.shouldShowCreateTicketButton(supportTickets: support?.supportTickets) {
                    createTicketButton
                        .padding(.vertical, 16)
                } else if let url = support?.supportURL(
                    localization: localization,
                    purchasesProvider: viewModel.purchasesProvider
                ),
                  viewModel.shouldShowContactSupport,
                  URLUtilities.canOpenURL(url) || RuntimeUtils.isSimulator {
                        contactSupportView(url)
                            .padding(.vertical, 16)
                }

                if customerInfoViewModel.shouldShowUserDetailsSection {
                    accountDetailsView
                }
            }
            .opacity(viewModel.isRefreshing ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isRefreshing)
        }
        .overlay {
            RestorePurchasesAlert(
                isPresented: self.$viewModel.showRestoreAlert,
                actionWrapper: self.viewModel.actionWrapper,
                customerCenterViewModel: customerInfoViewModel
            )
        }
        .applyIf(self.viewModel.screen.type == .management, apply: {
            $0.navigationTitle(self.viewModel.screen.title)
                .navigationBarTitleDisplayMode(.inline)
        })
    }

    @ViewBuilder
    var accountDetailsView: some View {
        Spacer().frame(height: 16)

        AccountDetailsSection(
            originalPurchaseDate: customerInfoViewModel.originalPurchaseDate,
            originalAppUserId: customerInfoViewModel.originalAppUserId,
            localization: localization
        )
    }

    @ViewBuilder
    func contactSupportView(_ url: URL) -> some View {
        AsyncButton {
            if RuntimeUtils.isSimulator {
                self.showSimulatorAlert = true
            } else {
                openURL(url)
            }
        } label: {
            CompatibilityLabeledContent(localization[.contactSupport])
        }
        .padding(.horizontal)
        .buttonStyle(.customerCenterButtonStyle(for: colorScheme))
    }

    var createTicketButton: some View {
        Button {
            viewModel.showCreateTicket = true
        } label: {
            CompatibilityLabeledContent(localization[.contactSupport])
        }
        .padding(.horizontal)
        .buttonStyle(.customerCenterButtonStyle(for: colorScheme))
        .tint(colorScheme == .dark ? .white : .black)
    }

    var seeAllSubscriptionsButton: some View {
        Button {
            viewModel.showAllPurchases = true
        } label: {
            CompatibilityLabeledContent(localization[.seeAllPurchases]) {
                Image(systemName: "chevron.forward")
            }
        }
        .padding(.horizontal)
        .buttonStyle(.customerCenterButtonStyle(for: colorScheme))
        .tint(colorScheme == .dark ? .white : .black)
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
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [.subscription],
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: SubscriptionDetailViewModel(
                        customerInfoViewModel: CustomerCenterViewModel(
                            uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
                        ),
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: true,
                        showVirtualCurrencies: false,
                        allowsMissingPurchaseAction: false,
                        purchaseInformation: .subscription,
                        refundRequestStatus: .success
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Yearly expiring - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [.free],
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: SubscriptionDetailViewModel(
                        customerInfoViewModel: CustomerCenterViewModel(
                            uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
                        ),
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: true,
                        showVirtualCurrencies: false,
                        allowsMissingPurchaseAction: false,
                        purchaseInformation: .free
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Free subscription - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [.consumable],
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: SubscriptionDetailViewModel(
                        customerInfoViewModel: CustomerCenterViewModel(
                            uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
                        ),
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: false,
                        showVirtualCurrencies: false,
                        allowsMissingPurchaseAction: false,
                        purchaseInformation: .consumable
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Consumable - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [],
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: SubscriptionDetailViewModel(
                        customerInfoViewModel: CustomerCenterViewModel(
                            uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
                        ),
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: true,
                        showVirtualCurrencies: false,
                        allowsMissingPurchaseAction: false,
                        purchaseInformation: nil
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Emtpy state - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [.mock(store: .playStore, isExpired: false)],
                        activeNonSubscriptionPurchases: [],
                        configuration: .default
                    ),
                    viewModel: SubscriptionDetailViewModel(
                        customerInfoViewModel: CustomerCenterViewModel(
                            uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
                        ),
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: true,
                        showVirtualCurrencies: false,
                        allowsMissingPurchaseAction: false,
                        purchaseInformation: .mock(store: .playStore, isExpired: false)
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Play Store - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [.mock(store: .playStore, isExpired: false)],
                        activeNonSubscriptionPurchases: [],
                        virtualCurrencies: VirtualCurrenciesFixtures.fourVirtualCurrencies,
                        configuration: .default
                    ),
                    viewModel: SubscriptionDetailViewModel(
                        customerInfoViewModel: CustomerCenterViewModel(
                            uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
                        ),
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: true,
                        showVirtualCurrencies: true,
                        allowsMissingPurchaseAction: false,
                        purchaseInformation: .mock(store: .playStore, isExpired: false)
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("4 VCs - \(colorScheme)")

            CompatibilityNavigationStack {
                SubscriptionDetailView(
                    customerInfoViewModel: CustomerCenterViewModel(
                        activeSubscriptionPurchases: [.mock(store: .playStore, isExpired: false)],
                        activeNonSubscriptionPurchases: [],
                        virtualCurrencies: VirtualCurrenciesFixtures.fiveVirtualCurrencies,
                        configuration: .default
                    ),
                    viewModel: SubscriptionDetailViewModel(
                        customerInfoViewModel: CustomerCenterViewModel(
                            uiPreviewPurchaseProvider: MockCustomerCenterPurchases()
                        ),
                        screen: CustomerCenterConfigData.default.screens[.management]!,
                        showPurchaseHistory: true,
                        showVirtualCurrencies: true,
                        allowsMissingPurchaseAction: false,
                        purchaseInformation: .mock(store: .playStore, isExpired: false)
                    )
                )
            }
            .preferredColorScheme(colorScheme)
            .previewDisplayName("5 VCs - \(colorScheme)")
        }
        .environment(\.localization, CustomerCenterConfigData.default.localization)
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

}

#endif

#endif
