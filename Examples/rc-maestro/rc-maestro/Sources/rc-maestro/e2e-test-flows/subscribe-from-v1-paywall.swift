//
//  subscribe-from-v1-paywall.swift
//  Maestro
//
//  Created by Rick van der Linden on 30/10/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

extension E2ETestFlowView {
    struct SubscriberFromV1Paywall: View {
        
        @State private var offering: Offering?
        @State private var presentPaywall = false
        
        var body: some View {
            VStack {
                Text("V1 Paywall - alternative offering")
                    .font(.largeTitle)
                
                if offering != nil {
                    Button("Present Paywall") {
                        presentPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                else {
                    Text("Loading offerings...")
                }
            }
            .task {
                let offerings = try? await Purchases.shared.offerings()
                self.offering = offerings?.offering(identifier: "paywall_v1")
            }
            .sheet(isPresented: $presentPaywall) {
                if let offering {
                    PaywallView(offering: offering)
                }
            }
            .multilineTextAlignment(.center)
        }
    }
}
