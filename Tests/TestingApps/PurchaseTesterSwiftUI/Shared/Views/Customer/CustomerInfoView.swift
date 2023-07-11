//
//  CustomerInfoView.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/3/22.
//

import Foundation
import SwiftUI
import RevenueCat

struct CustomerInfoView: View {

    let customerInfo: CustomerInfo
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(self.infos, id: \.name) { info in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(info.name)
                            .bold()
                        Text(info.value)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

}

private extension CustomerInfoView {

    var infos: [(name: String, value: String)] {
        return [
            ("App User ID", Purchases.shared.appUserID),
            ("Original App User ID", self.customerInfo.originalAppUserId),
            ("First Seen", self.date(self.customerInfo.firstSeen) ?? "-"),
            ("Original Application Version", self.customerInfo.originalApplicationVersion ?? "-"),
            ("Original Purchase Date", self.date(customerInfo.originalPurchaseDate) ?? "-"),
            ("Latest Expiration Date", self.date(customerInfo.latestExpirationDate) ?? "-"),
            ("Request Date", self.date(customerInfo.requestDate) ?? "-"),
            ("Entitlement Verification", self.customerInfo.entitlements.verification.description),
        ]
    }

    private func date(_ date: Date?) -> String? {
        return date.map { $0.formatted() }
    }

}
