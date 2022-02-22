//
//  AppDelegate.swift
//  PurchaseTester
//
//  Created by Ryan Kotzebue on 1/9/19.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import UIKit
import UserNotifications
import RevenueCat

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        Purchases.configure(withAPIKey: Constants.apiKey,
                            appUserID: nil,
                            observerMode: false,
                            userDefaults: nil,
                            useStoreKit2IfAvailable: true)

        Purchases.logLevel = .debug
        // set attributes to store additional, structured information for a user in RevenueCat.
        // More info: https://docs.revenuecat.com/docs/user-attributes
        Purchases.shared.setAttributes(["favorite_cat" : "garfield"])

        // we're requesting push notifications on app start only to showcase how to set the push token in RevenueCat
        requestPushNotificationsPermissions()
        
        Purchases.shared.checkTrialOrIntroDiscountEligibility(["com.revenuecat.monthly_4.99.1_week_intro"]) { introEligibilityDict in
            print(introEligibilityDict)
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Purchases.shared.setPushToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }

    private func requestPushNotificationsPermissions() {
        let userNotificationCenter = UNUserNotificationCenter.current()
        userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            print("Permission granted: \(granted)")
            if granted {
                self?.getNotificationSettings()
            }
        }
    }

    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
