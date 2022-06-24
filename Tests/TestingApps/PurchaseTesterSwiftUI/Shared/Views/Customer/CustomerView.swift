//
//  CustomerView.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/1/22.
//

import Foundation
import SwiftUI
import RevenueCat

struct CustomerView: View {
    let customerInfo: RevenueCat.CustomerInfo
    
    var body: some View {
        TabView {
            CustomerInfoView(customerInfo: customerInfo)
                .tabItem {
                    Image(systemName: "1.square.fill")
                    Text("Info")
                }
            EntitlementsView(customerInfo: customerInfo)
                .tabItem {
                    Image(systemName: "2.square.fill")
                    Text("Entitlements")
                }
            TransactionsView(customerInfo: customerInfo)
                .tabItem {
                    Image(systemName: "3.square.fill")
                    Text("Transactions")
                }
            SubscriberAttributesView(customerInfo: customerInfo)
                .tabItem {
                    Image(systemName: "4.square.fill")
                    Text("Subscriber Atts")
                }
        }.navigationTitle("Customer Info")
    }
}
