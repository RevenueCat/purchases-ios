//
//  AppContentView.swift
//  PaywallsPreview
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct AppContentView: View {

    private enum Tab {
        case examples
        case sandboxPaywalls
    }

    @ObservedObject
    private var configuration = Configuration.shared

    @State
    private var selectedTab: Tab = Purchases.isConfigured ? .sandboxPaywalls : .examples

    var body: some View {
        TabView(selection: $selectedTab) {

            if Purchases.isConfigured {
                APIKeyDashboardList()
                    .tabItem {
                        Label("Sandbox Paywalls", systemImage: "testtube.2")
                    }
                    .tag(Tab.sandboxPaywalls)
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

            #if !DEBUG
            if !Purchases.isConfigured {
                Text("Purchases is not configured")
            }
            #endif
        }
    }

    private var background: some View {
        Rectangle()
            .foregroundStyle(.orange)
            .opacity(0.05)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }



}


#if !os(macOS) && !os(watchOS)

private extension UIApplication {

    @available(iOS 13.0, macCatalyst 13.1, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @MainActor
    var currentWindowScene: UIWindowScene? {
        return self
            .connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first as? UIWindowScene
    }

}

#endif
