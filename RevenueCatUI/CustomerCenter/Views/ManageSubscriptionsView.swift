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

#if !os(macOS) && !os(tvOS) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsView: View {

    @Environment(\.openURL)
    var openURL

    @StateObject
    private var viewModel = ManageSubscriptionsViewModel()

    init() { }

    fileprivate init(viewModel: ManageSubscriptionsViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            HeaderView()

            if let subscriptionInformation = self.viewModel.subscriptionInformation {
                SubscriptionDetailsView(subscriptionInformation: subscriptionInformation,
                                        refundRequestStatus: viewModel.refundRequestStatus)
            }

            Spacer()

            ManageSubscriptionsButtonsView(viewModel: viewModel,
                                           openURL: openURL)
        }
        .task {
            await checkAndLoadInformation()
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension ManageSubscriptionsView {

    func checkAndLoadInformation() async {
        if !viewModel.isLoaded {
            await viewModel.loadSubscriptionInformation()
            await viewModel.loadCustomerCenterConfig()
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct HeaderView: View {
    var body: some View {
        Text("How can we help?")
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
    let refundRequestStatus: String?

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

            if let refundRequestStatus = refundRequestStatus {
                Text("Refund request status: \(refundRequestStatus)")
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
struct ManageSubscriptionsButtonsView: View {

    @ObservedObject
    private(set) var viewModel: ManageSubscriptionsViewModel

    let openURL: OpenURLAction

    var body: some View {
        VStack(spacing: 16) {
            if let configuration = viewModel.configuration {
                let filteredPaths = configuration.paths.filter { path in
                    #if targetEnvironment(macCatalyst)
                        return path.type == .refundRequest
                    #else
                        return true
                    #endif
                }
                ForEach(filteredPaths, id: \.id) { path in
                    Button(path.title.en_US) {
                        viewModel.handleAction(for: path)
                    }
                    .restorePurchasesAlert(isPresented: $viewModel.showRestoreAlert)
                    .buttonStyle(ManageSubscriptionsButtonStyle())
                }
            }
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsView_Previews: PreviewProvider {

    static var previews: some View {
        let viewModel = ManageSubscriptionsViewModel(
            configuration: CustomerCenterConfigTestData.customerCenterData,
            subscriptionInformation: CustomerCenterConfigTestData.subscriptionInformation)
        ManageSubscriptionsView(viewModel: viewModel)
    }

}

#endif

#endif
