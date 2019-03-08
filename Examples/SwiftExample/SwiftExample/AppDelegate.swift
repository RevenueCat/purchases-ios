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
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Purchases.debugLogsEnabled = true
        Purchases.configure(withAPIKey: "AahhcxDdDwYNehVmpLnaKbzhEnwErcZm", appUserID: nil)
        
        return true
    }
}

