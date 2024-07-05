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

    @ObservedObject
    private var configuration = Configuration.shared



    var body: some View {
        TabView {

            SamplePaywallsList()
                .tabItem {
                    Image("logo")
                        .renderingMode(.template)
                    Text("Examples")
                }

            AppList()
                .tabItem {
                    Label("My Apps", systemImage: "network")
                }

            if Purchases.isConfigured {
                APIKeyDashboardList()
                    .tabItem {
                        Label("Sandbox Paywalls", systemImage: "testtube.2")
                    }
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


#if !os(watchOS)

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
        }
    }

}

#endif
