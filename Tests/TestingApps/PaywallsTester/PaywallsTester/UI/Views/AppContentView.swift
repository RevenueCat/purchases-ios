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
        case myApps
        case sandboxPaywalls
    }

    @ObservedObject
    private var configuration = Configuration.shared

    @State
    private var selectedTab: Tab = {
        if Purchases.isConfigured && !Constants.sandboxPaywallSearch.isEmpty {
            return .sandboxPaywalls
        }
        #if os(macOS)
        return .myApps
        #else
        return .examples
        #endif
    }()

    var body: some View {
        TabView(selection: $selectedTab) {

            #if !os(macOS)
            SamplePaywallsList()
                .tabItem {
                    Image("logo")
                        .renderingMode(.template)
                    Text("Examples")
                }
                .tag(Tab.examples)
            #endif
            AppList()
                .tabItem {
                    Label("My Apps", systemImage: "network")
                }
                .tag(Tab.myApps)

            if Purchases.isConfigured {
                APIKeyDashboardList()
                    .tabItem {
                        Label("Sandbox Paywalls", systemImage: "testtube.2")
                    }
                    .tag(Tab.sandboxPaywalls)
            }

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

#if DEBUG

// TODO: Mock developer to instantiate AppContentView
@testable import RevenueCatUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct AppContentView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationStack {
            AppContentView()
              .environmentObject(ApplicationData())
        }
    }

}

#endif
