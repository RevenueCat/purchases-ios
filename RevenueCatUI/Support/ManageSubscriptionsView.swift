//
//  ManageSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import SwiftUI
import RevenueCat

@available(iOS 15.0, *)
public struct ManageSubscriptionsView: View {
    @State private var subscriptionInformation: SubscriptionInformation? = nil
    @State private var showRestoreAlert: Bool = false
    @Environment(\.openURL) var openURL

    public var body: some View {
        VStack {
            Text("How can we help?")
                .font(.title)
                .padding()

            if let subscriptionInformation = subscriptionInformation {
                Text("\(subscriptionInformation.title) - \(subscriptionInformation.duration)")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)

                Text("\(subscriptionInformation.price)")
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.gray)
                    .padding(.horizontal)

                Text("\(subscriptionInformation.willRenew ? "Renews" : "Expires"): \(subscriptionInformation.nextRenewal)")
                    .font(.caption)
                    .foregroundColor(Color.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom)
            }

            Spacer()

            Button("Didn't receive purchase") {
                self.showRestoreAlert = true
            }
            .restorePurchasesAlert(isPresented: self.$showRestoreAlert)
            .padding()
            .frame(width: 300)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("Change plans") {
                Task {
                    try await Purchases.shared.showManageSubscriptions()
                }
            }
            .padding()
            .frame(width: 300)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("Contact support") {
                Task {
                    openURL(self.createMailURL()!)
                }
            }
            .padding()


        }
        .task {
            try! await loadSubscriptionInformation()
        }
    }

    private struct SubscriptionInformation {
        let title: String
        let duration: String
        let price: String
        let nextRenewal: String
        let willRenew: Bool
    }

    private func loadSubscriptionInformation() async throws {
        self.subscriptionInformation = SubscriptionInformation(
            title: "Basic",
            duration: "Monthly",
            price: "4.99/month",
            nextRenewal: "June 1st, 2024",
            willRenew: false)
    }

    func createMailURL() -> URL? {
        let subject = "Support Request"
        let body = "Please describe your issue or question."
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = "mailto:support@revenuecat.com?subject=\(encodedSubject)&body=\(encodedBody)"
        return URL(string: urlString)
    }

}

@available(iOS 15.0, *)
#Preview {
    ManageSubscriptionsView()
}
