//
//  PurchaseTesterApp.swift
//  Shared
//
//  Created by Josh Holtz on 1/10/22.
//

import SwiftUI

import RevenueCat

@main
struct PurchaseTesterApp: App {
    @State private var revenueCatCustomerData = RevenueCatCustomerData()

    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Constants.apiKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(revenueCatCustomerData)
                .task {
                    for await customerInfo in Purchases.shared.customerInfoStream {
                        self.revenueCatCustomerData.customerInfo = customerInfo
                        self.revenueCatCustomerData.appUserID = Purchases.shared.appUserID
                    }
                }
        }
    }
}

class AppDelegate: NSObject {
}

extension AppDelegate: PurchasesDelegate {
    func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase makeDeferredPurchase: @escaping StartPurchaseBlock) {
        
        makeDeferredPurchase { (transaction, customerInfo, error, success) in
            print("Yay")
        }
    }
}

class RevenueCatCustomerData: ObservableObject {
    @Published var appUserID: String? = nil
    @Published var customerInfo: RevenueCat.CustomerInfo? = nil
}

extension RevenueCat.StoreProduct: Identifiable {}
