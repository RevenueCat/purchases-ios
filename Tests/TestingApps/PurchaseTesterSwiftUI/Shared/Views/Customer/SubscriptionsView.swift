//
//  SubscriptionsView.swift
//  PurchaseTester
//
//  Created by Álvaro Brey.
//

import Foundation
import SwiftUI
import RevenueCat

struct SubscriptionsView: View {

    let customerInfo: CustomerInfo

    var subscriptions: [SubscriptionInfo] {
        return self.customerInfo.subscriptionsByProductIdentifier
            .values
            .sorted { $0.productIdentifier < $1.productIdentifier }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if self.subscriptions.isEmpty {
                    Text("No subscriptions")
                } else {
                    ForEach(self.subscriptions, id: \.productIdentifier) { subscription in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(subscription.productIdentifier)
                                .bold()
                            ForEach(self.rows(for: subscription), id: \.name) { row in
                                Text("\(row.name): \(row.value)")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.horizontal)
    }

}

private extension SubscriptionsView {

    func rows(for subscription: SubscriptionInfo) -> [(name: String, value: String)] {
        return [
            ("Store", "\(subscription.store)"),
            ("Is Active", "\(subscription.isActive)"),
            ("Will Renew", "\(subscription.willRenew)"),
            ("Period Type", "\(subscription.periodType)"),
            ("Expires Date", self.date(subscription.expiresDate) ?? "-"),
            ("Grace Period Expires", self.date(subscription.gracePeriodExpiresDate) ?? "-"),
            ("Auto Resume Date", self.date(subscription.autoResumeDate) ?? "-"),
            ("Product Plan Identifier", subscription.productPlanIdentifier ?? "-"),
        ]
    }

    func date(_ date: Date?) -> String? {
        return date.map { $0.formatted() }
    }

}
