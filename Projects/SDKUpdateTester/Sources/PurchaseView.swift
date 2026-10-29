//
//  PurchaseView.swift
//  SDKUpdateTester
//
//  Created by Antonio Pallares on 2/10/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import RevenueCat
import SwiftUI

struct PurchaseView: View {

    // An offering also used by rc-maestro's E2E tests, which only require it to have no paywall attached.
    private static let offeringIdentifier = "no_paywall"

    @State private var activeEntitlements: String = "Loading..."
    @State private var isPurchasing = false
    @State private var statusMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Active entitlements")
                    .font(.headline)
                Text(activeEntitlements)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .accessibilityIdentifier("active_entitlements")
            }

            Button("Purchase subscription") {
                purchase()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing)
            .accessibilityIdentifier("purchase_button")

            if let statusMessage {
                Text(statusMessage)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("status_message")
            }
        }
        .padding()
        // Top-aligned so the status message appearing below doesn't shift the screenshotted label.
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationTitle("Purchase")
        .task {
            do {
                update(with: try await Purchases.shared.customerInfo())
            } catch {
                activeEntitlements = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func update(with customerInfo: CustomerInfo) {
        let identifiers = customerInfo.entitlements.active.keys.sorted()
        activeEntitlements = identifiers.isEmpty ? "None" : identifiers.joined(separator: ", ")
    }

    private func purchase() {
        isPurchasing = true
        statusMessage = nil
        Task {
            defer { isPurchasing = false }
            do {
                let offering = try await Purchases.shared.offerings().offering(identifier: Self.offeringIdentifier)
                guard let package = offering?.monthly else {
                    statusMessage = "No monthly package found in the '\(Self.offeringIdentifier)' offering"
                    return
                }
                let result = try await Purchases.shared.purchase(package: package)
                if result.userCancelled {
                    statusMessage = "Purchase cancelled"
                } else {
                    update(with: result.customerInfo)
                    statusMessage = "Purchased \(package.storeProduct.productIdentifier)"
                }
            } catch {
                statusMessage = "Purchase failed: \(error.localizedDescription)"
            }
        }
    }

}
