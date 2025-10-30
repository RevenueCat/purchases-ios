//
//  subscribe-from-v2-paywall.swift
//  Maestro
//
//  Created by Rick van der Linden on 30/10/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

extension E2ETestFlowView {
    struct SubscriberFromV2Paywall: View {
        
        @State private var presentPaywall = false
        
        var body: some View {
            Button("Present Paywall") {
                presentPaywall = true
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $presentPaywall) {
                PaywallView()
            }
        }
    }
}
