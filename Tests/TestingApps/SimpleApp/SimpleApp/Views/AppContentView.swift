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
        ZStack {
            self.background

            self.content
        }
        .presentPaywallIfNecessary {
            !$0.hasPro
        } purchaseCompleted: { _ in
            self.didPurchase = true
        }
    }

    private var background: some View {
        Rectangle()
            .foregroundStyle(.orange.gradient)
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

                Text("Thanks for purchasing!")
                    .hidden(if: !self.didPurchase)

                NavigationLink {
                    SamplePaywallsList()
                } label: {
                    Text("Sample paywalls")
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)

                NavigationLink {
                    OfferingsList()
                } label: {
                    Text("All offerings")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Spacer()

                BarChartView(data: (0..<10).map { _ in Double.random(in: 0..<100)})
                    .frame(maxWidth: .infinity)

                if let date = info.latestExpirationDate {
                    Text(verbatim: "Your subscription expires: \(date.formatted())")
                        .font(.caption)
                }

                Spacer()
            }
        }
        .padding(.horizontal)
        .navigationTitle("Simple App")
        .task {
            for await info in self.customerInfoStream {
                self.customerInfo = info
            }
        }
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
