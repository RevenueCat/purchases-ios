//
//  RestorePurchasesAlert.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import Foundation
import SwiftUI
import RevenueCat

@available(iOS 15.0, *)
public struct RestorePurchasesAlert: ViewModifier {
    @Binding var isPresented: Bool
    @State private var alertType: AlertType = .restorePurchases

    enum AlertType: Identifiable {
        case purchasesRecovered, purchasesNotFound, restorePurchases
        var id: Self { self }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL


    public func body(content: Content) -> some View {
        content
            .alert(isPresented: $isPresented) {
                switch self.alertType {
                case .restorePurchases:
                    Alert(
                        title: Text("Restore purchases"),
                        message: Text("Let’s take a look! We’re going to check your Apple account for missing purchases."),
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
                        openURL(self.createMailURL()!)
                    }),
                          secondaryButton: .cancel(Text("Cancel")) {
                        dismiss()
                    })
                }
            }
    }

    private func setAlertType(_ newType: AlertType) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.alertType = newType
            self.isPresented = true
        }
    }

    func createMailURL() -> URL? {
        let subject = "Support Request"
        let body = "Please describe your issue or question."
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = "mailto:support@revenuecat.com?subject=\(encodedSubject)&body=\(encodedBody)"
        return URL(string: urlString)
    }

}

@available(iOS 15.0, *)
public extension View {
    func restorePurchasesAlert(isPresented: Binding<Bool>) -> some View {
        self.modifier(RestorePurchasesAlert(isPresented: isPresented))
    }
}
