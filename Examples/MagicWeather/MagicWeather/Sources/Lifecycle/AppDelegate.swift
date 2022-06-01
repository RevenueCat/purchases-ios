//
//  AppDelegate.swift
//  Magic Weather
//
//  Created by Cody Kerns on 12/14/20.
//

import UIKit
import RevenueCat

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        /* Enable debug logs before calling `configure`. */
        Purchases.logLevel = .debug

        /*
         Initialize the RevenueCat Purchases SDK.
         
            - `appUserID` is nil by default, so an anonymous ID will be generated automatically by the Purchases SDK.
                Read more about Identifying Users here: https://docs.revenuecat.com/docs/user-ids
         
            - `observerMode` is false by default, so Purchases will automatically handle finishing transactions.
                Read more about Observer Mode here: https://docs.revenuecat.com/docs/observer-mode
         */

        Purchases.configure(
            with: Configuration.Builder(withAPIKey: Constants.apiKey)
                .with(usesStoreKit2IfAvailable: true)
                .build()
        )

        /// - Set the delegate to this instance of AppDelegate. Scroll down to see this implementation.
        Purchases.shared.delegate = self
        
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

/*
 Example implementation of PurchasesDelegate.
 */
extension AppDelegate: PurchasesDelegate {
    
    /// -  Whenever the `shared` instance of Purchases updates the PurchaserInfo cache, this method will be called.
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        /// - If necessary, refresh app UI from updated PurchaserInfo
    }

}
