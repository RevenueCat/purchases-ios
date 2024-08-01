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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
        let accentColor = color(from: self.appearance.accentColor, for: self.colorScheme)

        if #available(iOS 16.0, *) {
            NavigationStack {
                content
                    .navigationDestination(isPresented: .isNotNil(self.$viewModel.feedbackSurveyData)) {
                        if let feedbackSurveyData = self.viewModel.feedbackSurveyData {
                            FeedbackSurveyView(feedbackSurveyData: feedbackSurveyData)
                        }
                    }
            }.applyIf(accentColor != nil, apply: { $0.tint(accentColor) })
        } else {
            NavigationView {
                content
                    .background(NavigationLink(
                        destination: self.viewModel.feedbackSurveyData.map { data in
                            FeedbackSurveyView(feedbackSurveyData: data)
                        },
                        isActive: .isNotNil(self.$viewModel.feedbackSurveyData)
                    ) {
                        EmptyView()
                    })
            }.applyIf(accentColor != nil, apply: { $0.tint(accentColor) })
        }
    }

    @ViewBuilder
    var content: some View {
        ZStack {
            if let background = color(from: appearance.backgroundColor, for: colorScheme) {
                background.edgesIgnoringSafeArea(.all)
            }

            ScrollView {
                VStack {
                    if self.viewModel.isLoaded {
                        SubtitleTextView(subtitle: self.viewModel.screen.subtitle)

                        if let subscriptionInformation = self.viewModel.subscriptionInformation {
                            SubscriptionDetailsView(
                                subscriptionInformation: subscriptionInformation,
                                localization: self.localization,
                                refundRequestStatusMessage: self.viewModel.refundRequestStatusMessage)
                        }

                        ManageSubscriptionsButtonsView(viewModel: self.viewModel,
                                                       loadingPath: self.$viewModel.loadingPath)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding([.horizontal, .bottom])
                .frame(maxWidth: 400)
            }
        }
        .task {
            await loadInformationIfNeeded()
        }
        .navigationTitle(self.viewModel.screen.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
        let textColor = color(from: appearance.textColor, for: colorScheme)

        if let subtitle {
            Text(subtitle)
                .font(.subheadline)
                .padding([.horizontal])
                .multilineTextAlignment(.center)
                .applyIf(textColor != nil, apply: { $0.foregroundColor(textColor) })
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SubscriptionDetailsView: View {

    let iconWidth = 22.0
    let subscriptionInformation: SubscriptionInformation
    let localization: CustomerCenterConfigData.Localization
    let refundRequestStatusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading) {
                Text("\(subscriptionInformation.title)")
                    .font(.headline)

                let explanation = subscriptionInformation.active ? (
                     subscriptionInformation.willRenew ?
                            localization.commonLocalizedString(for: .subEarliestRenewal) :
                            localization.commonLocalizedString(for: .subEarliestExpiration)
                    ) : localization.commonLocalizedString(for: .subExpired)

                Text("\(explanation)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }.padding([.bottom], 10)

            Divider()
                .padding(.bottom)

            VStack(alignment: .leading, spacing: 16.0) {
                HStack(alignment: .center) {
                    Image(systemName: "coloncurrencysign.arrow.circlepath")
                        .accessibilityHidden(true)
                        .frame(width: iconWidth)
                    VStack(alignment: .leading) {
                        Text(localization.commonLocalizedString(for: .billingCycle))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text("\(subscriptionInformation.durationTitle)")
                            .font(.body)
                    }
                }

                HStack(alignment: .center) {
                    Image(systemName: "coloncurrencysign")
                        .accessibilityHidden(true)
                        .frame(width: iconWidth)
                    VStack(alignment: .leading) {
                        Text(localization.commonLocalizedString(for: .currentPrice))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text("\(subscriptionInformation.price)")
                            .font(.body)
                    }
                }

                if let nextRenewal =  subscriptionInformation.expirationDateString {

                    let expirationString = subscriptionInformation.active ? (
                        subscriptionInformation.willRenew ?
                            localization.commonLocalizedString(for: .nextBillingDate) :
                            localization.commonLocalizedString(for: .expires)
                    ) : localization.commonLocalizedString(for: .expired)

                    HStack(alignment: .center) {
                        Image(systemName: "calendar")
                            .accessibilityHidden(true)
                            .frame(width: iconWidth)
                        VStack(alignment: .leading) {
                            Text("\(expirationString)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text("\(String(describing: nextRenewal))")
                                .font(.body)
                        }
                    }
                }

                if let refundRequestStatusMessage = refundRequestStatusMessage {
                    HStack(alignment: .center) {
                        Image(systemName: "arrowshape.turn.up.backward")
                            .accessibilityHidden(true)
                            .frame(width: iconWidth)
                        VStack(alignment: .leading) {
                            Text(localization.commonLocalizedString(for: .refundStatus))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text("\(refundRequestStatusMessage)")
                                .font(.body)
                        }
                    }
                }
            }

        }
        .padding(24.0)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0.0, y: 10)
        .padding(.top)
        .padding(.bottom)
        .padding(.bottom)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
        VStack(spacing: 16) {
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

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
                TintedProgressView().transition(.opacity)
            } else {
                Text(path.title)
            }
        })
        .buttonStyle(ManageSubscriptionsButtonStyle())
        .disabled(self.viewModel.loadingPath != nil)
        .restorePurchasesAlert(isPresented: self.$viewModel.showRestoreAlert,
                               isRestoring: self.$viewModel.restoringPurchases)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SubscriptionDetailsView_Previews: PreviewProvider {

    static var previews: some View {
        SubscriptionDetailsView(
            subscriptionInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing,
            localization: CustomerCenterConfigTestData.customerCenterData.localization,
            refundRequestStatusMessage: "Success"
        )
        .previewDisplayName("Subscription Details - Monthly")
        .padding()

    }
}
#endif

#endif

#endif
