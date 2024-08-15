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

#if CUSTOMER_CENTER_ENABLED

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsView: View {

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization
    @Environment(\.colorScheme)
    private var colorScheme

    @StateObject
    private var viewModel: ManageSubscriptionsViewModel

    init(screen: CustomerCenterConfigData.Screen,
         customerCenterActionHandler: CustomerCenterActionHandler?) {
        let viewModel = ManageSubscriptionsViewModel(screen: screen,
                                                     customerCenterActionHandler: customerCenterActionHandler)
        self._viewModel = .init(wrappedValue: viewModel)
    }

    fileprivate init(viewModel: ManageSubscriptionsViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            content
                .navigationDestination(isPresented: .isNotNil(self.$viewModel.feedbackSurveyData)) {
                    if let feedbackSurveyData = self.viewModel.feedbackSurveyData {
                        FeedbackSurveyView(feedbackSurveyData: feedbackSurveyData)
                    }
                }
        } else {
            content
                .background(NavigationLink(
                    destination: self.viewModel.feedbackSurveyData.map { data in
                        FeedbackSurveyView(feedbackSurveyData: data)
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
            if let background = Color.from(colorInformation: appearance.backgroundColor, for: colorScheme) {
                background.edgesIgnoringSafeArea(.all)
            }

            if self.viewModel.isLoaded {
                List {
                    if let subtitle = self.viewModel.screen.subtitle {
                        SubtitleTextView(subtitle: subtitle)
                    }

                    if let subscriptionInformation = self.viewModel.subscriptionInformation {
                        Section {
                            SubscriptionDetailsView(
                                subscriptionInformation: subscriptionInformation,
                                localization: self.localization,
                                refundRequestStatusMessage: self.viewModel.refundRequestStatusMessage)
                        }
                    }

                    Section {
                        ManageSubscriptionsButtonsView(viewModel: self.viewModel,
                                                       loadingPath: self.$viewModel.loadingPath)
                    }
                }
            } else {
                TintedProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DismissCircleButton {
                    dismiss()
                }
            }
        }
        .task {
            await loadInformationIfNeeded()
        }
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
struct SubtitleTextView: View {

    private(set) var subtitle: String?
    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
        let textColor = Color.from(colorInformation: appearance.textColor, for: colorScheme)

        if let subtitle {
            Text(subtitle)
                .font(.subheadline)
                .padding([.horizontal])
                .multilineTextAlignment(.center)
                .applyIf(textColor != nil, apply: { $0.foregroundColor(textColor) })
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
            return true
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
        .restorePurchasesAlert(isPresented: self.$viewModel.showRestoreAlert)
        .sheet(item: self.$viewModel.promotionalOfferData,
               onDismiss: {
            Task {
                await self.viewModel.handleSheetDismiss()
            }
        },
               content: { promotionalOfferData in
            PromotionalOfferView(promotionalOffer: promotionalOfferData.promotionalOffer,
                                 product: promotionalOfferData.product,
                                 promoOfferDetails: promotionalOfferData.promoOfferDetails)
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
        let viewModelMonthlyRenewing = ManageSubscriptionsViewModel(
            screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
            subscriptionInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing,
            customerCenterActionHandler: nil,
            refundRequestStatusMessage: "Refund granted successfully!")
        ManageSubscriptionsView(viewModel: viewModelMonthlyRenewing)
            .previewDisplayName("Monthly renewing")
            .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
            .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)

        let viewModelYearlyExpiring = ManageSubscriptionsViewModel(
            screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
            subscriptionInformation: CustomerCenterConfigTestData.subscriptionInformationYearlyExpiring,
            customerCenterActionHandler: nil)
        ManageSubscriptionsView(viewModel: viewModelYearlyExpiring)
            .previewDisplayName("Yearly expiring")
            .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
            .environment(\.appearance, CustomerCenterConfigTestData.customerCenterData.appearance)
    }

}

#endif

#endif

#endif
