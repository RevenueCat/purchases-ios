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

    let customerInfoStream: AsyncStream<CustomerInfo>

    init() {
        self.init(Purchases.shared.customerInfoStream)
    }

    init(_ customerInfoStream: AsyncStream<CustomerInfo>) {
        self.customerInfoStream = customerInfoStream
    }

    #if DEBUG
    init(customerInfo: CustomerInfo) {
        self.init(.init(unfolding: { customerInfo }))
    }
    #endif

    @State
    private var customerInfo: CustomerInfo?

    @State
    private var didPurchase: Bool = false

    var body: some View {
        TabView {
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

            SamplePaywallsList()
                .tabItem {
                    Label("Examples", systemImage: "pawprint")
                }

            OfferingsList()
                .tabItem {
                    Label("All paywalls", systemImage: "network")
                }
        }
        .presentPaywallIfNeeded {
            !$0.hasPro
        } purchaseCompleted: { _ in
            self.didPurchase = true
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

                if self.didPurchase {
                    Text("Thanks for purchasing!")
                }

                Spacer()

                if let date = info.latestExpirationDate {
                    Text(verbatim: "Your subscription expires: \(date.formatted())")
                        .font(.caption)
                }

                Spacer()
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Simple App")
        .task {
            for await info in self.customerInfoStream {
                self.customerInfo = info
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
