//
//  MagicWeatherApp.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/11/21.
//

import SwiftUI
import RevenueCat

@main
struct MagicWeatherApp: App {
    
    init() {
        /* Enable debug logs before calling `configure`. */
        Purchases.logLevel = .debug
        
        /*
         Initialize the RevenueCat Purchases SDK.
         
         - `appUserID` is nil by default, so an anonymous ID will be generated automatically by the Purchases SDK.
            Read more about Identifying Users here: https://docs.revenuecat.com/docs/user-ids
         
         - `observerMode` is false by default, so Purchases will automatically handle finishing transactions.
            Read more about Observer Mode here: https://dz gocs.revenuecat.com/docs/observer-mode
         */

        Purchases.configure(
            with: Configuration.Builder(withAPIKey: Constants.apiKey)
                .with(usesStoreKit2IfAvailable: true)
                .build()
        )

        /* Set the delegate to our shared instance of PurchasesDelegateHandler */
        Purchases.shared.delegate = PurchasesDelegateHandler.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .task {
                    do {
                        // Fetch the available offerings
                        UserViewModel.shared.offerings = try await Purchases.shared.offerings()
                    } catch {
                        print("Error fetching offerings: \(error)")
                    }
                }
        }
    }
}
