//
//  PaywallsTesterApp.swift
//  PaywallsTester
//
//  Created by James Borthwick on 4/25/24.
//

import SwiftUI
import RevenueCat

@main
struct PaywallsTesterApp: App {

    @State
    private var webPurchaseRedemptionResultMessage: String?

    @State
    private var shouldShowWebPurchaseRedemptionResultAlert: Bool = false

    var body: some Scene {
        WindowGroup {
            AppContentView()
                .onWebPurchaseRedemptionAttempt { result in
                    let message: String?
                    switch result {
                    case .success(_):
                        message = "Redeemed web purchase successfully!"
                    case let .error(error):
                        message = "Web purchase redemption failed: \(error.localizedDescription)"
                    case .invalidToken:
                        message = "Web purchase redemption failed due to invalid token"
                    case .purchaseBelongsToOtherUser:
                        message = "Redemption link has already been redeemed. Cannot be redeemed again."
                    case let .expired(obfuscatedEmail):
                        message = "Redemption link expired. A new one has been sent to \(obfuscatedEmail)"
                    @unknown default:
                        message = "Unrecognized web purchase redemption result"
                    }
                    self.webPurchaseRedemptionResultMessage = message
                    self.shouldShowWebPurchaseRedemptionResultAlert = true
                }
                .alert(isPresented: self.$shouldShowWebPurchaseRedemptionResultAlert) {
                    return Alert(title: Text("Web purchase redemption attempt"),
                                 message: Text(self.webPurchaseRedemptionResultMessage ?? ""),
                                 dismissButton: .cancel(Text("Ok")) {
                        self.shouldShowWebPurchaseRedemptionResultAlert = false
                    })
                }
        }
    }

}
