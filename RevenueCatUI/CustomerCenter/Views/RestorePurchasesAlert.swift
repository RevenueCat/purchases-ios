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
            .modifier(
                AlertOrConfirmationDialog(
                    isPresented: $isPresented,
                    alertType: alertType,
                    title: alertTitle(),
                    message: alertMessage(),
                    actions: alertActions()
                )
            )
    }

    // swiftlint:disable:next function_body_length
    private func alertActions() -> [AlertOrConfirmationDialog.AlertAction] {
        switch alertType {
        case .purchasesRecovered:
            return [
                AlertOrConfirmationDialog.AlertAction(
                    title: localization.commonLocalizedString(for: .dismiss),
                    role: .cancel,
                    action: dismissAlert
                )
            ]

        case .purchasesNotFound:
            var actions: [AlertOrConfirmationDialog.AlertAction] = []

            if let onUpdateAppClick = customerCenterViewModel.onUpdateAppClick,
               customerCenterViewModel.shouldShowAppUpdateWarnings {
                actions.append(
                    AlertOrConfirmationDialog.AlertAction(
                        title: localization.commonLocalizedString(for: .updateWarningUpdate),
                        role: nil,
                        action: onUpdateAppClick
                    )
                )
            }

            if let url = supportURL {
                actions.append(
                    AlertOrConfirmationDialog.AlertAction(
                        title: localization.commonLocalizedString(for: .contactSupport),
                        role: nil,
                        action: { Task { openURL(url) } }
                    )
                )
            }

            actions.append(
                AlertOrConfirmationDialog.AlertAction(
                    title: localization.commonLocalizedString(for: .dismiss),
                    role: .cancel,
                    action: dismissAlert
                )
            )

            return actions

        case .restorePurchases:
            return [
                AlertOrConfirmationDialog.AlertAction(
                    title: localization.commonLocalizedString(for: .checkPastPurchases),
                    role: nil,
                    action: {
                        Task {
                            let alertType = await customerCenterViewModel.performRestore()
                            setAlertType(alertType)
                        }
                    }
                ),
                AlertOrConfirmationDialog.AlertAction(
                    title: localization.commonLocalizedString(for: .cancel),
                    role: .cancel,
                    action: dismissAlert
                )
            ]
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

/// This modifier is used to show either an Alert or ConfirmationDialog depending on the number of actions to avoid
/// SwiftUI logging the following warning about confirmation dialogs requiring actionable choices:
/// "A confirmation dialog was created without any actions. Confirmation dialogs should always provide
/// users with an actionable choice. Consider using an alert if there is no action that can be taken
/// in response to your presentation."
private struct AlertOrConfirmationDialog: ViewModifier {
    @Binding var isPresented: Bool
    let alertType: RestorePurchasesAlert.AlertType
    let title: String
    let message: String
    let actions: [AlertAction]

    struct AlertAction: Identifiable {
        let id = UUID()
        let title: String
        let role: ButtonRole?
        let action: () -> Void
    }

    func body(content: Content) -> some View {
        if actions.count < 3 {
            content.alert(
                title,
                isPresented: $isPresented,
                actions: {
                    ForEach(actions) { action in
                        Button(role: action.role) {
                            action.action()
                        } label: {
                            Text(action.title)
                        }
                    }
                },
                message: {
                    Text(message)
                }
            )
        } else {
            content.confirmationDialog(
                title,
                isPresented: $isPresented,
                actions: {
                    ForEach(actions) { action in
                        Button(role: action.role) {
                            action.action()
                        } label: {
                            Text(action.title)
                        }
                    }
                },
                message: {
                    Text(message)
                }
            )
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
