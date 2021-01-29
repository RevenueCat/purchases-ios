//
//  Magic_Weather_SwiftUIApp.swift
//  Shared
//
//  Created by Cody Kerns on 1/11/21.
//

import SwiftUI
import Purchases

@main
struct MagicWeatherApp: App {
    
    init() {
        /* Enable debug logs before calling `configure`. */
        Purchases.debugLogsEnabled = true
        
        /*
         Initialize the RevenueCat Purchases SDK.
         
         - appUserID is nil, so an anonymous ID will be generated automatically by the Purchases SDK. Read more about Identifying Users here: https://docs.revenuecat.com/docs/user-ids
         
         - observerMode is false, so Purchases will automatically handle finishing transactions. Read more about Observer Mode here: https://docs.revenuecat.com/docs/observer-mode
         */
        
        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: false)
        
        /* Set the delegate to our shared instance of PurchasesDelegateHandler */
        Purchases.shared.delegate = PurchasesDelegateHandler.shared
        
        /* Fetch the available offerings */
        Purchases.shared.offerings { (offerings, error) in
            UserViewModel.shared.objectWillChange.send()
            UserViewModel.shared.offerings = offerings
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
