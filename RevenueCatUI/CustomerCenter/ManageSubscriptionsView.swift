//
//  ManageSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
public struct ManageSubscriptionsView: View {

    @Environment(\.openURL)
    var openURL

    @StateObject
    private var viewModel = ManageSubscriptionsViewModel()

    public init() { }

    init(viewModel: ManageSubscriptionsViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    public var body: some View {
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
        .onAppear {
            checkAndLoadSubscriptionInformation()
        }
    }

    private func checkAndLoadSubscriptionInformation() {
        if !viewModel.isLoaded {
            Task {
                try! await viewModel.loadSubscriptionInformation()
            }
        }
    }

}

@available(iOS 15.0, *)
struct HeaderView: View {
    var body: some View {
        Text("How can we help?")
            .font(.title)
            .padding()
    }
}

@available(iOS 15.0, *)
struct SubscriptionDetailsView: View {
    let subscriptionInformation: SubscriptionInformation
    let refundRequestStatus: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(subscriptionInformation.title) - \(subscriptionInformation.duration)")
                .font(.subheadline)
                .padding(.horizontal)
                .padding(.top)

            Text("\(subscriptionInformation.price)")
                .font(.caption)
                .foregroundColor(Color.gray)
                .padding(.horizontal)

            Text("\(subscriptionInformation.renewalString): \(subscriptionInformation.nextRenewal)")
                .font(.caption)
                .foregroundColor(Color.gray)
                .padding(.horizontal)
                .padding(.bottom)

            if let refundRequestStatus = refundRequestStatus {
                Text("Refund request status: \(refundRequestStatus)")
                    .font(.caption)
                    .bold()
                    .foregroundColor(Color.gray)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
    }
}

@available(iOS 15.0, *)
struct ManageSubscriptionsButtonsView: View {

    @ObservedObject
    var viewModel: ManageSubscriptionsViewModel
    let openURL: OpenURLAction
    @State
    private var showRestoreAlert: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            if let configuration = viewModel.configuration {
                ForEach(configuration.paths, id: \.id) { path in
                    Button(path.title.en_US) {
                        handleAction(for: path)
                    }
                    .restorePurchasesAlert(isPresented: self.$showRestoreAlert)
                    .buttonStyle(ManageSubscriptionsButtonStyle())
                }
            }

            Button("Contact support") {
                Task {
                    openURL(URLUtilities.createMailURL()!)
                }
            }
            .padding()
        }
    }

    private func handleAction(for path: CustomerCenterData.HelpPath) {
        switch path.type {
        case .missingPurchase:
            self.showRestoreAlert = true
        case .refundRequest:
            Task {
                guard let subscriptionInformation = self.viewModel.subscriptionInformation else { return }
                let status = try await Purchases.shared.beginRefundRequest(forProduct: subscriptionInformation.productIdentifier)
                switch status {
                case .error:
                    self.viewModel.refundRequestStatus = "Error when requesting refund, try again"
                case .success:
                    self.viewModel.refundRequestStatus = "Refund granted successfully!"
                case .userCancelled:
                    self.viewModel.refundRequestStatus = "Refund canceled"
                }
            }
        case .changePlans:
            Task {
                try await Purchases.shared.showManageSubscriptions()
            }
        case .cancel:
            Task {
                try await Purchases.shared.showManageSubscriptions()
            }
        default:
            break
        }
    }
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct ManageSubscriptionsView_Previews: PreviewProvider {

    static var previews: some View {
        let viewModel = ManageSubscriptionsViewModel(configuration: CustomerCenterTestData.customerCenterData,
                                                     subscriptionInformation: CustomerCenterTestData.subscriptionInformation)
        ManageSubscriptionsView(viewModel: viewModel)
    }

}

#endif
