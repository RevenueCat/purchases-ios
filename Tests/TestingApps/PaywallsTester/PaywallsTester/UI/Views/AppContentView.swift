//
//  AppContentView.swift
//  PaywallsTester
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

/// Trimmed to the min/max sizing harness: the hot-reloaded local paywall, full
/// screen. There is deliberately no TabView — a tab bar would take a slice of the
/// window, and `\.paywallWindowSize` measures the paywall's container, so the
/// responsive rules would evaluate against a size the real app never sees.
struct AppContentView: View {

    var body: some View {
        #if os(macOS) && DEBUG
        if ProcessInfo.processInfo.arguments.contains("-MacOSPurchaseFocusRegression") {
            MacOSPurchaseFocusRegressionView()
        } else {
            self.content
        }
        #else
        self.content
        #endif
    }

    @ViewBuilder
    private var content: some View {
        #if DEBUG && !os(tvOS) && !os(watchOS)
        if #available(iOS 15.0, macOS 13.0, *) {
            LiveJSONPaywallView()
        } else {
            Text("Requires iOS 15 / macOS 13")
        }
        #else
        Text("The hot reload harness requires a DEBUG build on iOS or macOS.")
        #endif
    }

}
