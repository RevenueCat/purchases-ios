//
//  AppContentView.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct AppContentView: View {

    @State
    private var customerInfo: CustomerInfo?

    @State
    private var showingDefaultPaywall: Bool = false

    var body: some View {
        TabView {
            if Purchases.isConfigured {
                NavigationView {
                    ZStack {
                        self.background
                        self.content
                    }
                    .navigationTitle("Paywall Tester")
                }
                .tabItem {
                    Label("App", systemImage: "iphone")
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }

            #if DEBUG
            SamplePaywallsList()
                .tabItem {
                    Label("Examples", systemImage: "pawprint")
                }
            #endif

            if Purchases.isConfigured {
                OfferingsList()
                    .tabItem {
                        Label("All paywalls", systemImage: "network")
                    }

                UpsellView()
                    .tabItem {
                        Label("Upsell view", systemImage: "dollarsign")
                    }
                    .navigationTitle("Upsell view")

            }
        }
    }

    private var background: some View {
        Rectangle()
            .foregroundStyle(.orange)
            .opacity(0.05)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 20) {
            if let info = self.customerInfo {
                Text(verbatim: "You're signed in: \(info.originalAppUserId)")
                    .font(.callout)

                if self.customerInfo?.activeSubscriptions.count ?? 0 > 0 {
                    Text("Thanks for purchasing!")
                }

                Spacer()

                if let date = info.latestExpirationDate {
                    Text(verbatim: "Your subscription expires: \(date.formatted())")
                        .font(.caption)
                }

                Spacer()
            }
            Spacer()
            
            Button("Configure for demos") {
                Purchases.configure(withAPIKey: Configuration.apiKeyFromCIForDemos)
                self.observeCustomerInfoStream()
            }
            .prominentButtonStyle()

            Button("Configure for testing") {
                Purchases.configure(withAPIKey: Configuration.apiKeyFromCIForTesting)
                self.observeCustomerInfoStream()
            }
            .prominentButtonStyle()
            
            Button("Present default paywall") {
                showingDefaultPaywall.toggle()
            }
            .prominentButtonStyle()
        }
        .padding(.horizontal)
        .padding(.bottom, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Simple App")
        .task {
            self.observeCustomerInfoStream()
        }
        #if DEBUG
        .overlay {
            if #available(iOS 16.0, macOS 13.0, *) {
                DebugView()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        #endif
        .sheet(isPresented: self.$showingDefaultPaywall) {
            NavigationView {
                PaywallView()
                #if targetEnvironment(macCatalyst)
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            Button {
                                self.showingDefaultPaywall = false
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                #endif
            }
        }
    }

    private func observeCustomerInfoStream() {
        Task {
            if Purchases.isConfigured {
                for await info in Purchases.shared.customerInfoStream {
                    self.customerInfo = info
                    self.showingDefaultPaywall = self.showingDefaultPaywall && info.activeSubscriptions.count == 0
                }
            }
        }
    }

}

private extension View {
    func prominentButtonStyle() -> some View {
        self.modifier(ProminentButtonStyle())
    }
}

private struct ProminentButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: 50)
            .font(.headline)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

extension CustomerInfo {

    var hasPro: Bool {
        return self.entitlements.active.contains { $1.identifier == Configuration.entitlement }
    }

}

#if DEBUG

@testable import RevenueCatUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct AppContentView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationStack {
            AppContentView()
        }
    }

}

#endif
