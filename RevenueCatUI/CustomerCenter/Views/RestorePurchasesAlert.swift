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
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct RestorePurchasesAlert: View {

    @Environment(\.openURL)
    var openURL

    @Binding
    private var isPresented: Bool

    @ObservedObject
    private var customerCenterViewModel: CustomerCenterViewModel

    @StateObject
    private var viewModel: RestorePurchasesAlertViewModel

    @Environment(\.localization)
    private var localization

    @Environment(\.supportInformation)
    private var supportInformation: CustomerCenterConfigData.Support?

    init(
        isPresented: Binding<Bool>,
        actionWrapper: CustomerCenterActionWrapper,
        customerCenterViewModel: CustomerCenterViewModel
    ) {
        self.init(
            isPresented: isPresented,
            viewModel: RestorePurchasesAlertViewModel(actionWrapper: actionWrapper),
            customerCenterViewModel: customerCenterViewModel
        )
    }

    fileprivate init(
        isPresented: Binding<Bool>,
        viewModel: RestorePurchasesAlertViewModel,
        customerCenterViewModel: CustomerCenterViewModel
    ) {
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.customerCenterViewModel = customerCenterViewModel
    }

    private var supportURL: URL? {
        guard let supportInformation = self.supportInformation else { return nil }
        let subject = self.localization[.defaultSubject]
        let body = supportInformation.calculateBody(self.localization,
                                                    purchasesProvider: customerCenterViewModel.purchasesProvider)
        return URLUtilities.createMailURLIfPossible(email: supportInformation.email,
                                                    subject: subject,
                                                    body: body)
    }

    var body: some View {
        AlertOrConfirmationDialog(
            isPresented: $isPresented,
            alertType: self.viewModel.alertType,
            title: alertTitle(),
            message: alertMessage(),
            actions: alertActions()
        )
        .task(id: isPresented) {
            if isPresented {
                await viewModel.performRestore(purchasesProvider: customerCenterViewModel.purchasesProvider)
            }
        }
    }

    private func alertActions() -> [AlertOrConfirmationDialog.AlertAction] {
        switch self.viewModel.alertType {
        case .loading:
            return []
        case .purchasesRecovered:
            return [
                AlertOrConfirmationDialog.AlertAction(
                    title: localization[.done],
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

            if let url = supportInformation?.supportURL(
                localization: localization,
                purchasesProvider: customerCenterViewModel.purchasesProvider
            ), URLUtilities.canOpenURL(url) {
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
            return localization[.purchasesRestoring]
        case .purchasesRecovered:
            return localization[.purchasesRecovered]
        case .purchasesNotFound:
            return localization[.purchasesNotFound]
        }
    }

    private func alertMessage() -> String? {
        switch self.viewModel.alertType {
        case .loading:
            return nil
        case .purchasesRecovered:
            return localization[.purchasesRecoveredExplanation]
        case .purchasesNotFound:
            var message = localization[.purchasesNotRecoveredExplanation]
            if customerCenterViewModel.shouldShowAppUpdateWarnings {
                message += "\n\n" + localization[.updateWarningDescription]
            }
            return message
        }
    }

    private func dismissAlert() {
        self.customerCenterViewModel.onDismissRestorePurchasesAlert()
        self.isPresented = false
        self.viewModel.alertType = .loading
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct AlertOrConfirmationDialog: View {

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

    var body: some View {
        ZStack {
            if isPresented {
                Color.black
                    .opacity(alertType == .loading ? 0.15 : 0)
                    .animation(.easeInOut, value: alertType)
                    .ignoresSafeArea()

                if alertType == .loading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(title)
                            .font(.headline)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                } else {
                    if actions.count < 3 {
                        Color.clear
                            .alert(
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
                    } else {
                        Color.clear
                            .confirmationDialog(
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
        }
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

    override func performRestore(purchasesProvider: CustomerCenterPurchasesType) async {
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
        let viewModelApple = CustomerCenterViewModel(
            activeSubscriptionPurchases: [.subscription],
            activeNonSubscriptionPurchases: [],
            configuration: CustomerCenterConfigData.default
        )

        RestorePurchasesAlert(
            isPresented: $isPresented,
            viewModel: MockRestorePurchasesAlertViewModel(alertType: alertType),
            customerCenterViewModel: viewModelApple
        )
        .environment(\.localization, CustomerCenterConfigData.default.localization)
        .emergeRenderingMode(.window)
    }

}
#endif

#endif
