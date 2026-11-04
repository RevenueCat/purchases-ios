//
//  SDKUpdateTesterApp.swift
//  SDKUpdateTester
//
//  Created by Antonio Pallares on 2/10/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import RevenueCat
import SwiftUI

/// Barebones app used by the SDK update Maestro tests.
///
/// It must only use long-standing public APIs, since it's compiled against both the latest released SDK
/// and the local SDK sources.
@main
struct SDKUpdateTesterApp: App {

    init() {
        Purchases.logLevel = .verbose
        Purchases.configure(withAPIKey: Constants.apiKey)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }

}

enum Constants {

    static let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? ""
    }()

    /// The app user ID used by the "Log in" button, passed by Maestro as a launch argument.
    static var appUserIDToLogIn: String? {
        UserDefaults.standard.string(forKey: "app_user_id_to_log_in").flatMap { $0.isEmpty ? nil : $0 }
    }

}
