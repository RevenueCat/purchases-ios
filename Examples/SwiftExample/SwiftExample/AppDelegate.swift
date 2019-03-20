//
//  AppDelegate.swift
//  SwiftExample
//
//  Created by Ryan Kotzebue on 1/9/19.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import UIKit
import Purchases

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PurchasesDelegate {

    var window: UIWindow?
    var deferment: RCDeferredPromotionalPurchaseBlock? = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Purchases.debugLogsEnabled = true
        Purchases.configure(withAPIKey: "AahhcxDdDwYNehVmpLnaKbzhEnwErcZm", appUserID: nil)
        Purchases.shared.delegate = self
        return true
    }
    
    func purchases(_ purchases: Purchases,
                            shouldPurchasePromoProduct product: SKProduct,
                            defermentBlock makeDeferredPurchase: @escaping RCDeferredPromotionalPurchaseBlock) {
        makeDeferredPurchase { (transaction, purchaserInfo, error, userCancelled) in
            if let e = error {
                print("PURCHASE ERROR: - \(e.localizedDescription)")

            } else if purchaserInfo?.activeEntitlements.contains("pro_cat") ?? false {
                print("Purchased Pro Cats 🎉")
            }
        }
    }

}

