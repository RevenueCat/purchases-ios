//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RestorePurchasesAlert.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

#if CUSTOMER_CENTER_ENABLED

import Foundation
import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct RestorePurchasesAlert: ViewModifier {

    @Binding
    var isPresented: Bool
    @Environment(\.openURL)
    var openURL

    @EnvironmentObject private var customerCenterViewModel: CustomerCenterViewModel

    @State
    private var alertType: AlertType = .restorePurchases
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.localization)
    private var localization
    @Environment(\.supportInformation)
    private var supportInformation: CustomerCenterConfigData.Support?

    private var supportURL: URL? {
        guard let supportInformation = self.supportInformation else { return nil }
        let subject = self.localization.commonLocalizedString(for: .defaultSubject)
        let body = self.localization.commonLocalizedString(for: .defaultBody)
        return URLUtilities.createMailURLIfPossible(email: supportInformation.email,
                                                    subject: subject,
                                                    body: body)
    }

    enum AlertType: Identifiable {
        case purchasesRecovered, purchasesNotFound, restorePurchases
        var id: Self { self }
    }

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $isPresented) {
                switch self.alertType {
                case .restorePurchases:
                    return Alert(
                        title: Text("Restore purchases"),
                        message: Text(
                                    """
                                    Let’s take a look! We’re going to check your Apple account for missing purchases.
                                    """),
                        primaryButton: .default(Text("Check past purchases"), action: {
                            Task {
                                let alertType = await self.customerCenterViewModel.performRestore()
                                self.setAlertType(alertType)
                            }
                        }),
                        secondaryButton: .cancel(Text(localization.commonLocalizedString(for: .cancel)))
                    )

                case .purchasesRecovered:
                    return Alert(title: Text("Purchases recovered!"),
                                 message: Text("We applied the previously purchased items to your account. " +
                                               "Sorry for the inconvenience."),
                                 dismissButton: .cancel(Text(localization.commonLocalizedString(for: .dismiss))) {
                        dismiss()
                    })

                case .purchasesNotFound:
                    let message = Text("We couldn't find any additional purchases under this account. \n\n" +
                                       "Contact support for assistance if you think this is an error.")
                    if let url = supportURL {
                        return Alert(title: Text(""),
                                     message: message,
                                     primaryButton: .default(
                                        Text(localization.commonLocalizedString(for: .contactSupport))
                                     ) {
                                         Task {
                                             openURL(url)
                                         }
                                     },
                                     secondaryButton: .cancel(Text(localization.commonLocalizedString(for: .dismiss))) {
                                         dismiss()
                                     })
                    } else {
                        return Alert(title: Text(""),
                                     message: message,
                                     dismissButton: .default(Text(localization.commonLocalizedString(for: .dismiss))) {
                                         dismiss()
                                     })
                    }
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

#endif

#endif
