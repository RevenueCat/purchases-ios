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

    @ObservedObject
    private var configuration = Configuration.shared

    @State
    private var customerInfo: CustomerInfo?

    @State
    private var showingDefaultPaywall: Bool = false

    @State
    private var customerInfoTask: Task<(), Never>? = nil

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

            Text("Currently configured for \(self.descriptionForCurrentMode())")
                .font(.footnote)

            ConfigurationButton(title: "Configure for demos", mode: .demos, configuration: configuration) {
                self.configuration.currentMode = .demos
            }

            ConfigurationButton(title: "Configure for testing", mode: .testing, configuration: configuration) {
                self.configuration.currentMode = .testing
            }

            ProminentButton(title: "Present default paywall") {
                self.showingDefaultPaywall.toggle()
            }

            #if !os(watchOS)
            ProminentButton(title: "Present PaywallViewController") {
                self.presentPaywallViewController()
            }
            #endif
        }
        .padding(.horizontal)
        .padding(.bottom, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Simple App")
        #if DEBUG && !os(watchOS)
        .overlay {
            if #available(iOS 16.0, macOS 13.0, *) {
                DebugView()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        #endif
        .sheet(isPresented: self.$showingDefaultPaywall) {
            PaywallView(displayCloseButton: Configuration.defaultDisplayCloseButton)
        }
        .task(id: self.configuration.currentMode) {
            if Purchases.isConfigured {
                for await info in Purchases.shared.customerInfoStream {
                    self.customerInfo = info
                    self.showingDefaultPaywall = self.showingDefaultPaywall && info.activeSubscriptions.isEmpty
                }
            }
        }
    }

    private func descriptionForCurrentMode() -> String {
        switch self.configuration.currentMode {
        case .custom:
            return "the API set locally in Configuration.swift"
        case .testing:
            return "the Paywalls Tester app in RevenueCat Dashboard"
        case .demos:
            return "Demos"
        case .listOnly:
            return "showcasing the different Paywall Templates and Modes available"
        }
    }

    #if !os(watchOS)
    private func presentPaywallViewController() {
        let paywall = PaywallViewController(displayCloseButton: Configuration.defaultDisplayCloseButton)
        paywall.modalPresentationStyle = .pageSheet

        guard let rootController = UIApplication
            .shared
            .currentWindowScene?
            .keyWindow?
            .rootViewController else {
            assertionFailure("Couldn't find root view controller")
            return
        }

        rootController.present(paywall, animated: true)
    }
    #endif

}

private struct ProminentButton: View {

    var title: String
    var action: () -> Void
    var background: Color = .accentColor

    var body: some View {
        Button(action: self.action) {
            Text(self.title)
                .bold()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        #if !os(watchOS)
        .controlSize(.large)
        #endif
        .tint(self.background)
        .foregroundColor(.white)
    }

}

private struct ConfigurationButton: View {

    var title: String
    var mode: Configuration.Mode
    @ObservedObject var configuration: Configuration
    var action: () -> Void

    var body: some View {
        ProminentButton(
            title: self.title,
            action: self.action,
            background: self.configuration.currentMode == self.mode ? Color.gray : Color.accentColor
        )
        .disabled(self.configuration.currentMode == self.mode)
    }

}

extension CustomerInfo {

    var hasPro: Bool {
        return self.entitlements.active.contains { $1.identifier == Configuration.entitlement }
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
