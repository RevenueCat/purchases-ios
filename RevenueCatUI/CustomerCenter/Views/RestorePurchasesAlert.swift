//
//  RestorePurchasesAlert.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import Foundation
import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct RestorePurchasesAlert: ViewModifier {

    @Binding
    var isPresented: Bool
    @Environment(\.openURL)
    var openURL

    @State
    private var alertType: AlertType = .restorePurchases
    @Environment(\.dismiss)
    private var dismiss

    enum AlertType: Identifiable {
        case purchasesRecovered, purchasesNotFound, restorePurchases
        var id: Self { self }
    }

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $isPresented) {
                switch self.alertType {
                case .restorePurchases:
                    Alert(
                        title: Text("Restore purchases"),
                        message: Text(
                                    """
                                    Let’s take a look! We’re going to check your Apple account for missing purchases.
                                    """),
                        primaryButton: .default(Text("Check past purchases"), action: {
                            Task {
                                guard let customerInfo = try? await Purchases.shared.restorePurchases() else {
                                    // todo: handle errors
                                    self.setAlertType(.purchasesNotFound)
                                    return
                                }
                                let hasEntitlements = customerInfo.entitlements.active.count > 0
                                if hasEntitlements {
                                    self.setAlertType(.purchasesRecovered)
                                } else {
                                    self.setAlertType(.purchasesNotFound)
                                }
                            }
                        }),
                        secondaryButton: .cancel(Text("Cancel"))
                    )

                case .purchasesRecovered:
                    Alert(title: Text("Purchases recovered!"),
                          message: Text("We applied the previously purchased items to your account. " +
                                        "Sorry for the inconvenience."),
                          dismissButton: .default(Text("Dismiss")) {
                        dismiss()
                    })

                case .purchasesNotFound:

                    Alert(title: Text(""),
                          message: Text("We couldn’t find any additional purchases under this account. \n\n" +
                                        "Contact support for assistance if you think this is an error."),
                          primaryButton: .default(Text("Contact Support"), action: {
                        // todo: make configurable
                        openURL(URLUtilities.createMailURL()!)
                    }),
                          secondaryButton: .cancel(Text("Cancel")) {
                        dismiss()
                    })
                }
            }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension RestorePurchasesAlert {

    func setAlertType(_ newType: AlertType) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.alertType = newType
            self.isPresented = true
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {
    func restorePurchasesAlert(isPresented: Binding<Bool>) -> some View {
        self.modifier(RestorePurchasesAlert(isPresented: isPresented))
    }
}
