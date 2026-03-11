//
//  CustomPurchaseLogicPaywall.swift
//  PaywallsTester
//
//  Demonstrates custom purchase logic (purchasesAreCompletedBy: .myApp) with paywalls.
//  When the user taps the purchase button, a confirmation dialog lets them pick
//  the simulated result: Success, Cancelled, or Error.
//

#if DEBUG

import RevenueCat
import RevenueCatUI
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CustomPurchaseLogicPaywall: View {

    let offering: Offering

    @State private var pendingPurchase: CheckedContinuation<(userCancelled: Bool, error: Error?), Never>?
    @State private var pendingRestore: CheckedContinuation<(success: Bool, error: Error?), Never>?
    @State private var showPurchaseDialog = false
    @State private var showRestoreDialog = false

    var body: some View {
        PaywallView(
            offering: offering,
            displayCloseButton: true,
            performPurchase: { _ in
                await withCheckedContinuation { continuation in
                    self.pendingPurchase = continuation
                    self.showPurchaseDialog = true
                }
            },
            performRestore: {
                await withCheckedContinuation { continuation in
                    self.pendingRestore = continuation
                    self.showRestoreDialog = true
                }
            }
        )
        .confirmationDialog("Simulated Purchase Result", isPresented: $showPurchaseDialog) {
            Button("Success") {
                pendingPurchase?.resume(returning: (userCancelled: false, error: nil))
                pendingPurchase = nil
            }
            Button("Cancelled") {
                pendingPurchase?.resume(returning: (userCancelled: true, error: nil))
                pendingPurchase = nil
            }
            Button("Error") {
                let error = NSError(
                    domain: "com.revenuecat.test.purchaselogic",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Simulated purchase error"]
                )
                pendingPurchase?.resume(returning: (userCancelled: false, error: error))
                pendingPurchase = nil
            }
        } message: {
            Text("Choose the result for the custom purchase logic callback.")
        }
        .confirmationDialog("Simulated Restore Result", isPresented: $showRestoreDialog) {
            Button("Success") {
                pendingRestore?.resume(returning: (success: true, error: nil))
                pendingRestore = nil
            }
            Button("Error") {
                let error = NSError(
                    domain: "com.revenuecat.test.purchaselogic",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Simulated restore error"]
                )
                pendingRestore?.resume(returning: (success: false, error: error))
                pendingRestore = nil
            }
        } message: {
            Text("Choose the result for the custom restore logic callback.")
        }
    }
}

#endif
