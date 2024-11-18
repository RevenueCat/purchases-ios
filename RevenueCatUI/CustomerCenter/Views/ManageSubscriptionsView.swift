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
         customerCenterActionHandler: CustomerCenterActionHandler?) {
        let viewModel = ManageSubscriptionsViewModel(screen: screen,
                                                     customerCenterActionHandler: customerCenterActionHandler)
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
            if self.viewModel.isLoaded {
                List {

                    if let subscriptionInformation = self.viewModel.subscriptionInformation {
                        Section {
                            SubscriptionDetailsView(
                                subscriptionInformation: subscriptionInformation,
                                refundRequestStatus: self.viewModel.refundRequestStatus)
                        }
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
                }
            } else {
                TintedProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .compatibleTopBarTrailing) {
                DismissCircleButton()
            }
        }
        .task {
            await loadInformationIfNeeded()
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
        .navigationTitle(self.viewModel.screen.title)
        .navigationBarTitleDisplayMode(.inline)
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension ManageSubscriptionsView {

    func loadInformationIfNeeded() async {
        if !self.viewModel.isLoaded {
            await viewModel.loadScreen()
        }
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsButtonsView: View {

    @ObservedObject
    var viewModel: ManageSubscriptionsViewModel
    @Binding
    var loadingPath: CustomerCenterConfigData.HelpPath?
    @Environment(\.openURL)
    var openURL

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    var body: some View {
        let filteredPaths = self.viewModel.screen.paths.filter { path in
#if targetEnvironment(macCatalyst)
            return path.type == .refundRequest
#else
            return path.type != .unknown
#endif
        }
        ForEach(filteredPaths, id: \.id) { path in
            ManageSubscriptionButton(path: path, viewModel: self.viewModel)
        }
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionButton: View {

    let path: CustomerCenterConfigData.HelpPath
    @ObservedObject var viewModel: ManageSubscriptionsViewModel

    @Environment(\.appearance) private var appearance: CustomerCenterConfigData.Appearance

    var body: some View {
        AsyncButton(action: {
            await self.viewModel.determineFlow(for: path)
        }, label: {
            if self.viewModel.loadingPath?.id == path.id {
                TintedProgressView()
            } else {
                Text(path.title)
            }
        })
        .disabled(self.viewModel.loadingPath != nil)
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
                    subscriptionInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing,
                    customerCenterActionHandler: nil,
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
                    subscriptionInformation: CustomerCenterConfigTestData.subscriptionInformationYearlyExpiring,
                    customerCenterActionHandler: nil)
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
