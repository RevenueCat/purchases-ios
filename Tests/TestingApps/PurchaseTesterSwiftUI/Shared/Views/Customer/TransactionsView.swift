//
//  TransactionsView.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/3/22.
//

import Foundation
import SwiftUI
import RevenueCat

struct TransactionsView: View {
    let customerInfo: RevenueCat.CustomerInfo
    
    let dateFormatter: DateFormatter = {
        var df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(self.customerInfo.nonSubscriptionTransactions) { transaction in
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(transaction.productIdentifier)")
                            .bold()
                        Text("\(dateFormatter.string(from: transaction.purchaseDate))")
                    }
                }
            }
        }.padding(.horizontal, 20)
    }
}
