//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallFixturesApp.swift
//
//  Created by Facundo Menzella on 8/5/26.

import RevenueCat
import SwiftUI

/// Renders one paywall fixture and nothing else. UI tests name the fixture through the
/// `PAYWALL_FIXTURE` environment variable, so there is no list to navigate and no state to reset;
/// run it without one to pick from the list by hand.
@main
struct PaywallFixturesApp: App {

    /// The SDK refuses to render a paywall until it is configured. The key is a placeholder and
    /// deliberately not a real one: offerings and customer info come from the fixture, purchases are
    /// stubbed, so no request needs to succeed and no secret belongs in this app.
    init() {
        Purchases.configure(withAPIKey: "appl_paywallFixtures")
    }

    var body: some Scene {
        WindowGroup {
            FixtureRootView(
                requestedFixture: ProcessInfo.processInfo.environment["PAYWALL_FIXTURE"]
            )
        }
    }

}
