//
//  CustomPaywallView.swift
//  RCTTester
//
//  Mirrors the customer's RevenueCatPaywallView pattern to reproduce
//  the Posthog analytics inflation issue (paywall callbacks firing multiple times).
//

import SwiftUI
import RevenueCat
import RevenueCatUI

@available(iOS 17.0, *)
struct CustomPaywallView: View {
    @Bindable var viewModel: CustomPaywallViewModel

    var body: some View {
        CustomPaywallViewUI(
            state: viewModel.state,
            onClose: viewModel.onClose,
            onPurchaseInitiated: viewModel.onPurchaseInitiated,
            onPurchaseCancelled: viewModel.onPurchaseCancelled,
            onPurchaseError: viewModel.onPurchaseError,
            onPurchaseCompleted: viewModel.onPurchaseCompleted,
            onRestoreCompleted: viewModel.onRestoreCompleted,
            onRetry: {
                Task {
                    await viewModel.onRetry()
                }
            }
        )
        .task {
            await viewModel.onFirstAppearTask()
        }
    }
}

@available(iOS 17.0, *)
private struct CustomPaywallViewUI: View {

    let state: CustomPaywallViewModel.State
    let onClose: () -> Void
    let onPurchaseInitiated: () -> Void
    let onPurchaseCancelled: () -> Void
    let onPurchaseError: (Error) -> Void
    let onPurchaseCompleted: (CustomerInfo) async -> Void
    let onRestoreCompleted: (CustomerInfo) async -> Void
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ProgressView("Loading paywall…")
            }

        case let .error(message):
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Error")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry", action: onRetry)
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
            }

        case let .loaded(offering):
            RevenueCatUI.PaywallView(
                offering: offering,
                displayCloseButton: true
            )
            .onRequestedDismissal {
                onClose()
            }
            .onPurchaseInitiated { _, resume in
                Task { @MainActor in
                    onPurchaseInitiated()
                    resume(shouldProceed: true)
                }
            }
            .onPurchaseCompleted { customerInfo in
                Task { await onPurchaseCompleted(customerInfo) }
            }
            .onPurchaseCancelled {
                onPurchaseCancelled()
            }
            .onRestoreCompleted { customerInfo in
                Task { await onRestoreCompleted(customerInfo) }
            }
            .onPurchaseFailure { error in
                onPurchaseError(error)
            }
        }
    }
}
