//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointTesterApp.swift
//
//  Created by Rick van der Linden.
//

import Foundation
import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

@main
struct CheckpointTesterApp: App {

    @StateObject private var model: CheckpointDemoModel
    init() {
        let model = CheckpointDemoModel()
        self._model = StateObject(wrappedValue: model)

        Purchases.logLevel = .debug
        Self.configurePurchases()
        model.configurePaywallPresenter()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: self.model)
        }
    }

    // MARK: - New checkpoint public API implementation

    private static func configurePurchases() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
              !apiKey.isEmpty,
              !apiKey.contains("$(") else {
            fatalError("Generate CheckpointTester with a valid TUIST_RC_API_KEY.")
        }

        if !Purchases.isConfigured {
            Purchases.configure(withAPIKey: apiKey)
        }
    }

}
