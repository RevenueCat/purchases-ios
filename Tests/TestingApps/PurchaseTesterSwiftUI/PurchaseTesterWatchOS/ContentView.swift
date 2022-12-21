//
//  ContentView.swift
//  PurchaseTesterWatchOS Watch App
//
//  Created by Nacho Soto on 12/12/22.
//

import SwiftUI

import Core
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

struct HomeView: View {

    @EnvironmentObject
    var revenueCatCustomerData: RevenueCatCustomerData

    var body: some View {
        if let customerInfo = self.revenueCatCustomerData.customerInfo,
           !customerInfo.entitlements.active.isEmpty {
            Text("Thanks for buying a subscription!")
        } else {
            Button {
                Task<Void, Never> {
                    do {
                        _ = try await Purchases.shared.restorePurchases()
                    } catch {
                        print("Error: \(error)")
                    }
                }
            } label: {
                Text("Restore purchases")
            }
        }

    }

}

final class RevenueCatCustomerData: ObservableObject {

    @Published var appUserID: String? = nil
    @Published var customerInfo: CustomerInfo? = nil

}
