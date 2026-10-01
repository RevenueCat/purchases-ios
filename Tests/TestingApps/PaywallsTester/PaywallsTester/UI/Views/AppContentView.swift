//
//  AppContentView.swift
//  PaywallsTester
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct AppContentView: View {

    private enum Tab {
        case examples
        case livePaywalls
        #if os(macOS) && DEBUG
        case purchaseFocusRegression
        #endif
    }

    @State
    private var selectedTab: Tab = Purchases.isConfigured ? .livePaywalls : .examples

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

    private var content: some View {
        TabView(selection: $selectedTab) {

            if Purchases.isConfigured {
                APIKeyDashboardList()
                    .tabItem {
                        Label("Live Paywalls", systemImage: "testtube.2")
                    }
                    .tag(Tab.livePaywalls)
            }

            #if !os(macOS)
            SamplePaywallsList()
                .tabItem {
                    Image("logo")
                        .renderingMode(.template)
                    Text("Examples")
                }
                .tag(Tab.examples)
            #endif

            #if os(macOS) && DEBUG
            MacOSPurchaseFocusRegressionView()
                .tabItem {
                    Label("Focus Regression", systemImage: "keyboard")
                }
                .tag(Tab.purchaseFocusRegression)
            #endif

            if !Purchases.isConfigured {
                Text("Purchases is not configured")
            }
        }
    }

}
