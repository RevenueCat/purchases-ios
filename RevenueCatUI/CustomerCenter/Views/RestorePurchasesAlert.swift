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
        let body = supportInformation.calculateBody(self.localization)
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
            .confirmationDialog(
                alertTitle(),
                isPresented: $isPresented,
                actions: {
                    switch alertType {
                    case .purchasesRecovered:
                        PurchasesRecoveredActions()
                    case .purchasesNotFound:
                        PurchasesNotFoundActions()
                    case .restorePurchases:
                        RestorePurchasesActions()
                    }
                },
                message: {
                    Text(alertMessage())
                }
            )
    }

    // MARK: - Actions
    @ViewBuilder
    // swiftlint:disable:next identifier_name
    private func RestorePurchasesActions() -> some View {
        Button {
            Task {
                let alertType = await self.customerCenterViewModel.performRestore()
                self.setAlertType(alertType)
            }
        } label: {
            Text(localization.commonLocalizedString(for: .checkPastPurchases))
        }

        Button(role: .cancel) {
            dismissAlert()
        } label: {
            Text(localization.commonLocalizedString(for: .cancel))
        }
    }

    @ViewBuilder
    // swiftlint:disable:next identifier_name
    private func PurchasesRecoveredActions() -> some View {
        Button(role: .cancel) {
            dismissAlert()
        } label: {
            Text(localization.commonLocalizedString(for: .dismiss))
        }
    }

    @ViewBuilder
    // swiftlint:disable:next identifier_name
    private func PurchasesNotFoundActions() -> some View {

        if let onUpdateAppClick = customerCenterViewModel.onUpdateAppClick,
           customerCenterViewModel.shouldShowAppUpdateWarnings {
            Button {
                onUpdateAppClick()
            } label: {
                Text(localization.commonLocalizedString(for: .updateWarningUpdate))
                    .bold()
            }
        }

        if let url = supportURL {
            Button {
                Task {
                    openURL(url)
                }
            } label: {
                Text(localization.commonLocalizedString(for: .contactSupport))
            }
        }

        Button(role: .cancel) {
            dismissAlert()
        } label: {
            Text(localization.commonLocalizedString(for: .dismiss))
        }
    }

    // MARK: - Strings
    private func alertTitle() -> String {
        switch self.alertType {
        case .purchasesRecovered:
            return localization.commonLocalizedString(for: .purchasesRecovered)
        case .purchasesNotFound:
            return ""
        case .restorePurchases:
            return localization.commonLocalizedString(for: .restorePurchases)
        }
    }

    private func alertMessage() -> String {
        switch self.alertType {
        case .purchasesRecovered:
            return localization.commonLocalizedString(for: .purchasesRecoveredExplanation)
        case .purchasesNotFound:
            var message = localization.commonLocalizedString(for: .purchasesNotRecovered)
            if customerCenterViewModel.shouldShowAppUpdateWarnings {
                message += "\n\n" + localization.commonLocalizedString(for: .updateWarningDescription)
            }
            return message
        case .restorePurchases:
            return localization.commonLocalizedString(for: .goingToCheckPurchases)
        }
    }

    private func dismissAlert() {
        self.alertType = .restorePurchases
        dismiss()
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
