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

    let customerInfoStream: AsyncStream<CustomerInfo>?

    init(customerInfoStream: AsyncStream<CustomerInfo>?) {
        self.customerInfoStream = customerInfoStream
    }

    #if DEBUG
    init(customerInfo: CustomerInfo) {
        self.init(customerInfoStream: .init(unfolding: { customerInfo }))
    }
    #endif

    @State
    private var customerInfo: CustomerInfo?

    @State
    private var showingDefaultPaywall: Bool = false

    var body: some View {
        TabView {
            if self.isPurchasesConfigured {
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

            if self.isPurchasesConfigured {
                OfferingsList()
                    .tabItem {
                        Label("All paywalls", systemImage: "network")
                    }
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
            Button("Present default paywall") {
                showingDefaultPaywall.toggle()
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: 50)
            .font(.headline)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.bottom, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Simple App")
        .task {
            if let stream = self.customerInfoStream {
                for await info in stream {
                    self.customerInfo = info
                    self.showingDefaultPaywall = info.activeSubscriptions.count == 0
                }
                
            }
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

    private var isPurchasesConfigured: Bool {
        return self.customerInfoStream != nil
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
            AppContentView(customerInfo: TestData.customerInfo)
        }
    }

}

#endif
