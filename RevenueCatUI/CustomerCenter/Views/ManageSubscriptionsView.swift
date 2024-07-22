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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct ManageSubscriptionsView: View {

    @Environment(\.openURL)
    var openURL

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @StateObject
    private var viewModel: ManageSubscriptionsViewModel

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

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
            NavigationStack {
                content
                    .navigationDestination(isPresented: .constant(self.viewModel.feedbackSurveyData != nil)) {
                        if let feedbackSurveyData = self.viewModel.feedbackSurveyData {
                            FeedbackSurveyView(feedbackSurveyData: feedbackSurveyData)
                                .onDisappear {
                                    self.viewModel.feedbackSurveyData = nil
                                }
                        }
                    }
            }
        } else {
            NavigationView {
                content
                    .background(NavigationLink(
                        destination: self.viewModel.feedbackSurveyData.map { data in
                            FeedbackSurveyView(feedbackSurveyData: data)
                                .onDisappear {
                                    self.viewModel.feedbackSurveyData = nil
                                }
                        },
                        isActive: .constant(self.viewModel.feedbackSurveyData != nil)
                    ) {
                        EmptyView()
                    })
            }
        }
    }

    @ViewBuilder
    var content: some View {
        VStack {
            if self.viewModel.isLoaded {
                HeaderView(viewModel: self.viewModel)

                if let subscriptionInformation = self.viewModel.subscriptionInformation {
                    SubscriptionDetailsView(subscriptionInformation: subscriptionInformation,
                                            localization: localization,
                                            refundRequestStatusMessage: self.viewModel.refundRequestStatusMessage)
                }

                Spacer()

                ManageSubscriptionsButtonsView(viewModel: self.viewModel,
                                               loadingPath: self.$viewModel.loadingPath)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .task {
            await loadInformationIfNeeded()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
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
@available(visionOS, unavailable)
struct HeaderView: View {

    @ObservedObject
    private(set) var viewModel: ManageSubscriptionsViewModel

    var body: some View {
        Text(self.viewModel.screen.title)
            .font(.title)
            .padding()
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
                    .frame(maxWidth: 200, alignment: .leading)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }.padding([.bottom], 10)

            HStack(alignment: .center) {
                Image(systemName: "coloncurrencysign.arrow.circlepath")
                    .accessibilityHidden(true)
                    .frame(width: iconWidth)
                VStack(alignment: .leading) {
                    Text(localization.commonLocalizedString(for: .billingCycle))
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text("\(subscriptionInformation.durationTitle)")
                        .font(.caption)
                }
            }

            HStack(alignment: .center) {
                Image(systemName: "coloncurrencysign")
                    .accessibilityHidden(true)
                    .frame(width: iconWidth)
                VStack(alignment: .leading) {
                    Text(localization.commonLocalizedString(for: .currentPrice))
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text("\(subscriptionInformation.price)")
                        .font(.caption)
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
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Text("\(String(describing: nextRenewal))")
                            .font(.caption)
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
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Text("\(refundRequestStatusMessage)")
                            .font(.caption)
                    }
                }
            }
        }.padding()
            .padding(.horizontal)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 4)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct ManageSubscriptionsButtonsView: View {

    @ObservedObject
    var viewModel: ManageSubscriptionsViewModel
    @Binding
    var loadingPath: CustomerCenterConfigData.HelpPath?

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
@available(visionOS, unavailable)
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
        .buttonStyle(ManageSubscriptionsButtonStyle())
        .disabled(self.viewModel.loadingPath != nil)
    }
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
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
