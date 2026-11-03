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
    struct SubscribeFromV1Paywall: View {

        enum GetOfferingsState {
            case loading
            case loaded(Offering)
            case failed(Error)
        }

        @State private var offeringsState: GetOfferingsState = .loading
        @State private var presentPaywall = false

        var body: some View {
            VStack {
                Text("V1 Paywall - alternative offering")
                    .font(.largeTitle)

                switch offeringsState {
                case .loading:
                    Text("Loading offerings...")
                case .loaded(let offering):
                    Button("Present Paywall") {
                        presentPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $presentPaywall) {
                        PaywallView(offering: offering)
                    }
                case .failed(let error):
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                }

                EntitlementView(identifier: "pro")
            }
            .task {
                do {
                    let offerings = try await Purchases.shared.offerings()
                    if let offering = offerings.offering(identifier: "paywall_v1") {
                        offeringsState = .loaded(offering)
                    } else {
                        offeringsState = .failed(OfferingError.notFound)
                    }
                } catch {
                    offeringsState = .failed(error)
                }
            }
            .multilineTextAlignment(.center)
        }

        enum OfferingError: LocalizedError {
            case notFound

            var errorDescription: String? {
                switch self {
                case .notFound:
                    return "Offering 'paywall_v1' not found"
                }
            }
        }
    }
}
