//
//  ContentView.swift
//  Shared
//
//  Created by Josh Holtz on 1/10/22.
//

import SwiftUI

import RevenueCat

struct ContentView: View {

    let configuration: ConfiguredPurchases

    @StateObject
    private var revenueCatCustomerData = RevenueCatCustomerData()

    var body: some View {
        HomeView()
            .environmentObject(self.revenueCatCustomerData)
            .task {
                for await customerInfo in self.configuration.purchases.customerInfoStream {
                    self.revenueCatCustomerData.customerInfo = customerInfo
                    self.revenueCatCustomerData.appUserID = self.configuration.purchases.appUserID
                }
            }
    }

}

final class RevenueCatCustomerData: ObservableObject {

    @Published var appUserID: String? = nil
    @Published var customerInfo: CustomerInfo? = nil

}
