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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var revenueCatCustomerData = RevenueCatCustomerData()
    
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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        Purchases.logLevel = .debug
        Purchases.configure(with: Configuration
            .builder(withAPIKey: Constants.apiKey)
            .with(usesStoreKit2IfAvailable: true)
            .build())
        Purchases.shared.delegate = self

        return true
    }
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
