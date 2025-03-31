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
import RevenueCatUI
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct RestorePurchasesAlert: ViewModifier {

    @Environment(\.openURL)
    var openURL

    @Binding
    private var isPresented: Bool

    @EnvironmentObject private var customerCenterViewModel: CustomerCenterViewModel
    @StateObject private var viewModel: RestorePurchasesAlertViewModel

    @Environment(\.localization)
    private var localization
    @Environment(\.supportInformation)
    private var supportInformation: CustomerCenterConfigData.Support?

    init(
        isPresented: Binding<Bool>,
        actionWrapper: CustomerCenterActionWrapper
    ) {
        self.init(isPresented: isPresented,
                  viewModel: RestorePurchasesAlertViewModel(
                    actionWrapper: actionWrapper
                  ))
    }

    fileprivate init(
        isPresented: Binding<Bool>,
        viewModel: RestorePurchasesAlertViewModel
    ) {
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    private var supportURL: URL? {
        guard let supportInformation = self.supportInformation else { return nil }
        let subject = self.localization[.defaultSubject]
        let body = supportInformation.calculateBody(self.localization)
        return URLUtilities.createMailURLIfPossible(email: supportInformation.email,
                                                    subject: subject,
                                                    body: body)
    }

    func body(content: Content) -> some View {
        content
            .modifier(
                AlertOrConfirmationDialog(
                    isPresented: $isPresented,
                    alertType: self.viewModel.alertType,
                    title: alertTitle(),
                    message: alertMessage(),
                    actions: alertActions()
                )
            )
            .task(id: isPresented) {
                if isPresented {
                    await viewModel.performRestore()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: self.viewModel.alertType)
    }

    private func alertActions() -> [AlertOrConfirmationDialog.AlertAction] {
        switch self.viewModel.alertType {
        case .loading:
            return []
        case .purchasesRecovered:
            return [
                AlertOrConfirmationDialog.AlertAction(
                    title: localization[.dismiss],
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
                        title: localization[.updateWarningUpdate],
                        role: nil,
                        action: onUpdateAppClick
                    )
                )
            }

            if let url = supportURL {
                actions.append(
                    AlertOrConfirmationDialog.AlertAction(
                        title: localization[.contactSupport],
                        role: nil,
                        action: { Task { openURL(url) } }
                    )
                )
            }

            actions.append(
                AlertOrConfirmationDialog.AlertAction(
                    title: localization[.dismiss],
                    role: .cancel,
                    action: dismissAlert
                )
            )

            return actions
        }
    }

    // MARK: - Strings
    private func alertTitle() -> String {
        switch self.viewModel.alertType {
        case .loading:
            return localization[.restoring]
        case .purchasesRecovered:
            return localization[.purchasesRecovered]
        case .purchasesNotFound:
            return ""
        }
    }

    private func alertMessage() -> String? {
        switch self.viewModel.alertType {
        case .loading:
            return nil
        case .purchasesRecovered:
            return localization[.purchasesRecoveredExplanation]
        case .purchasesNotFound:
            var message = localization[.purchasesNotRecovered]
            if customerCenterViewModel.shouldShowAppUpdateWarnings {
                message += "\n\n" + localization[.updateWarningDescription]
            }
            return message
        }
    }

    private func dismissAlert() {
        self.viewModel.dismiss()
        self.isPresented = false
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
    let alertType: RestorePurchasesAlertViewModel.AlertType
    let title: String
    let message: String?
    let actions: [AlertAction]

    struct AlertAction: Identifiable {
        let id = UUID()
        let title: String
        let role: ButtonRole?
        let action: () -> Void
    }

    // swiftlint:disable:next function_body_length
    func body(content: Content) -> some View {
        if actions.count < 3 {
            if alertType == .loading && isPresented {
                content
                    .overlay {
                        ZStack {
                            Color.black.opacity(0.3)

                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text(title)
                                    .font(.headline)
                            }
                            .padding(24)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                    }.ignoresSafeArea()
            } else {
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
                        if let message {
                            Text(message)
                        }
                    }
                )
            }
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
                    if let message {
                        Text(message)
                    }
                }
            )
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {

    func restorePurchasesAlert(
        isPresented: Binding<Bool>,
        actionWrapper: CustomerCenterActionWrapper
    ) -> some View {
        self.modifier(RestorePurchasesAlert(isPresented: isPresented, actionWrapper: actionWrapper))
    }

}

#if DEBUG
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class MockRestorePurchasesAlertViewModel: RestorePurchasesAlertViewModel {

    init(alertType: AlertType) {
        super.init(actionWrapper: CustomerCenterActionWrapper())
        self.alertType = alertType
    }

    override func performRestore() async {
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct RestorePurchasesAlert_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreviewContainer(alertType: .loading)
                .previewDisplayName("Loading Forever")

            PreviewContainer(alertType: .purchasesRecovered)
                .previewDisplayName("Purchases Recovered")

            PreviewContainer(alertType: .purchasesNotFound)
                .previewDisplayName("Purchases Not Found")
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct PreviewContainer: View {

    let alertType: RestorePurchasesAlertViewModel.AlertType
    @State private var isPresented = true

    var body: some View {

        let purchaseInformationApple =
        CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing
        let viewModelApple = CustomerCenterViewModel(purchaseInformation: purchaseInformationApple,
                                                     configuration: CustomerCenterConfigTestData.customerCenterData)
        Color.clear
            .modifier(
                RestorePurchasesAlert(
                    isPresented: $isPresented,
                    viewModel: MockRestorePurchasesAlertViewModel(alertType: alertType)
                )
            )
            .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
            .environmentObject(viewModelApple)
    }

}
#endif

#endif
