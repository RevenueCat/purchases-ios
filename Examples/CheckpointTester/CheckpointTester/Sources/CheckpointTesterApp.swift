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
@_spi(Internal) import RevenueCat
@_spi(Internal) import RevenueCatUI
import SwiftUI

@main
struct CheckpointTesterApp: App {

    @StateObject private var model: CheckpointDemoModel
    @StateObject private var analyticsTracker: GlobalCheckpointAnalyticsTracker

    init() {
        let analyticsTracker = GlobalCheckpointAnalyticsTracker()
        let model = CheckpointDemoModel()
        self._model = StateObject(wrappedValue: model)
        self._analyticsTracker = StateObject(wrappedValue: analyticsTracker)

        Purchases.logLevel = .debug
        Self.configurePurchases(analyticsTracker: analyticsTracker)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                model: self.model,
                analyticsTracker: self.analyticsTracker
            )
        }
    }

    // MARK: - New checkpoint public API implementation

    // This section is the app-side setup for the new public API. Everything below the
    // `setCheckpointWorkflowData` call is demo infrastructure that stands in for workflows
    // the SDK will fetch from RevenueCat's server in production.
    private static func configurePurchases(analyticsTracker: GlobalCheckpointAnalyticsTracker) {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
              apiKey.hasPrefix("appl_"),
              !apiKey.contains("$(") else {
            fatalError("Generate CheckpointTester with a valid TUIST_RC_API_KEY.")
        }

        let purchases = Purchases.isConfigured
            ? Purchases.shared
            : Purchases.configure(withAPIKey: apiKey)
        purchases.checkpointListener = analyticsTracker

        // Demo-only: production SDKs fetch these workflow documents from RevenueCat's server.
        purchases.setCheckpointWorkflowData(DemoWorkflowLoader.loadBundledWorkflowData())
    }

}
