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

    @StateObject
    private var viewModel: ManageSubscriptionsViewModel
    @ObservedObject
    private var completionHandler: CustomerCenterCompletionHandler

    init(screen: CustomerCenterConfigData.Screen,
         appearance: CustomerCenterConfigData.Appearance,
         completionHandler: CustomerCenterCompletionHandler) {
        let viewModel = ManageSubscriptionsViewModel(screen: screen, appearance: appearance)
        self._viewModel = .init(wrappedValue: viewModel)
        self._completionHandler = .init(initialValue: completionHandler)
    }

    fileprivate init(viewModel: ManageSubscriptionsViewModel,
                     completionHandler: CustomerCenterCompletionHandler) {
        self._viewModel = .init(wrappedValue: viewModel)
        self._completionHandler = .init(initialValue: completionHandler)
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
                    .navigationDestination(isPresented: .constant(self.viewModel.feedbackSurveyData != nil)) {
                        if let feedbackSurveyData = self.viewModel.feedbackSurveyData {
                            FeedbackSurveyView(feedbackSurveyData: feedbackSurveyData,
                                               appearance: self.viewModel.appearance)
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
                            FeedbackSurveyView(feedbackSurveyData: data,
                                               appearance: self.viewModel.appearance)
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
                                            refundRequestStatusMessage: self.viewModel.refundRequestStatusMessage)
                }

                Spacer()

                ManageSubscriptionsButtonsView(viewModel: self.viewModel,
                                               completionHandler: self.completionHandler,
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

    let subscriptionInformation: SubscriptionInformation
    let refundRequestStatusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(subscriptionInformation.title) - \(subscriptionInformation.durationTitle)")
                .font(.subheadline)
                .padding([.horizontal, .top])

            Text("\(subscriptionInformation.price)")
                .font(.caption)
                .foregroundColor(Color.gray)
                .padding(.horizontal)

            if let nextRenewal =  subscriptionInformation.nextRenewalString {
                Text("\(subscriptionInformation.renewalString): \(String(describing: nextRenewal))")
                    .font(.caption)
                    .foregroundColor(Color.gray)
                    .padding([.horizontal, .bottom])
            }

            if let refundRequestStatusMessage = refundRequestStatusMessage {
                Text("Refund request status: \(refundRequestStatusMessage)")
                    .font(.caption)
                    .bold()
                    .foregroundColor(Color.gray)
                    .padding([.horizontal, .bottom])
            }
        }
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
    @ObservedObject
    var completionHandler: CustomerCenterCompletionHandler
    @Binding
    var loadingPath: CustomerCenterConfigData.HelpPath?
    @Environment(\.openURL)
    var openURL

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
            Button("Contact support") {
                Task {
                    openURL(URLUtilities.createMailURL()!)
                }
                completionHandler.supportContacted()
            }
            .padding()
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

    var body: some View {
        AsyncButton(action: {
            await self.viewModel.determineFlow(for: path)
        }, label: {
            Text(path.title)
        })
        .restorePurchasesAlert(isPresented: self.$viewModel.showRestoreAlert)
        .sheet(isPresented: self.$viewModel.isShowingPromotionalOffer, onDismiss: {
            Task {
                await self.viewModel.handleSheetDismiss()
            }
        }, content: {
            if let promotionalOffer = self.viewModel.promotionalOffer,
               let product = self.viewModel.product,
               let promoOfferDetails = self.viewModel.promoOfferDetails,
               let localization = self.viewModel.localization {
                PromotionalOfferView(promotionalOffer: promotionalOffer,
                                     product: product,
                                     promoOfferDetails: promoOfferDetails,
                                     localization: localization,
                                     appearance: self.viewModel.appearance)
            }
        })
        .buttonStyle(ManageSubscriptionsButtonStyle(appearance: self.viewModel.appearance))
        .disabled(self.viewModel.loadingPath?.id == path.id)
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
        let viewModel = ManageSubscriptionsViewModel(
            screen: CustomerCenterConfigTestData.customerCenterData.screens[.management]!,
            appearance: CustomerCenterConfigTestData.customerCenterData.appearance,
            subscriptionInformation: CustomerCenterConfigTestData.subscriptionInformation)
        ManageSubscriptionsView(viewModel: viewModel, completionHandler: .default())
    }

}

#endif

#endif
