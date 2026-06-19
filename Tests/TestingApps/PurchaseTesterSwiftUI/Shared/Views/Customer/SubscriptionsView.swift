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
            ("Store", self.storeName(subscription.store)),
            ("Is Active", "\(subscription.isActive)"),
            ("Will Renew", "\(subscription.willRenew)"),
            ("Period Type", self.periodTypeName(subscription.periodType)),
            ("Expires Date", self.date(subscription.expiresDate) ?? "-"),
            ("Grace Period Expires", self.date(subscription.gracePeriodExpiresDate) ?? "-"),
            ("Auto Resume Date", self.date(subscription.autoResumeDate) ?? "-"),
        ]
    }

    func date(_ date: Date?) -> String? {
        return date.map { $0.formatted() }
    }

    func storeName(_ store: Store) -> String {
        switch store {
        case .appStore: return "App Store"
        case .macAppStore: return "Mac App Store"
        case .playStore: return "Play Store"
        case .stripe: return "Stripe"
        case .promotional: return "Promotional"
        case .unknownStore: return "Unknown"
        case .amazon: return "Amazon"
        case .rcBilling: return "RevenueCat Billing"
        case .external: return "External"
        case .paddle: return "Paddle"
        case .testStore: return "Test Store"
        case .galaxy: return "Galaxy Store"
        @unknown default: return "Unknown"
        }
    }

    func periodTypeName(_ periodType: PeriodType) -> String {
        switch periodType {
        case .normal: return "Normal"
        case .intro: return "Intro"
        case .trial: return "Trial"
        case .prepaid: return "Prepaid"
        @unknown default: return "Unknown"
        }
    }

}
