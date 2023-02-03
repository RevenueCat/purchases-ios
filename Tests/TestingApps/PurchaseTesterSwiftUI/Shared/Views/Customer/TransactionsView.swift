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

    let customerInfo: CustomerInfo
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(self.customerInfo.nonSubscriptions) { transaction in
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(transaction.productIdentifier)")
                            .bold()
                        Text("\(transaction.purchaseDate.formatted()))")
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

}
