//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterInjectedPaywall.swift
//
//  Created by Monika on 6/10/2026.

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)
@available(iOS 15.0, *)
struct CustomerCenterInjectedPaywall<DefaultContent: View>: View {
    @ObservedObject var viewModel: NoSubscriptionsCardViewModel
    @ViewBuilder let defaultContent: () -> DefaultContent
    @State private var workflow: WorkflowContext?
    @State private var loaded = false
    @State private var failure: String?
    @State private var customVariables: [String: CustomVariableValue] = [:]
    @State private var attempt = 0
    @State private var promoEligible = false

    @ViewBuilder var body: some View {
        if viewModel.purchasesProvider is CustomerCenterPreviewProvider {
            previewContent
        } else {
            defaultContent()
        }
    }

    private var previewContent: some View {
        Group {
            if loaded, let provider = viewModel.purchasesProvider as? CustomerCenterPreviewProvider,
               let offering = viewModel.offering {
                injectedPaywall(provider: provider, offering: offering)
            } else if let failure {
                VStack {
                    Text(failure)
                    Button("Retry") { attempt += 1 }
                    Button("Close") { viewModel.hidePaywall() }
                }
            } else if loaded {
                Text("The configured preview offering is unavailable.")
                Button("Close") { viewModel.hidePaywall() }
            } else {
                ProgressView()
            }
        }
        .customPaywallVariables(customVariables)
        .environment(\.openURL, OpenURLAction { url in
            if let provider = viewModel.purchasesProvider as? CustomerCenterPreviewProvider {
                Task { try? await provider.handlePreviewAction(.openURL(url)) }
            }
            return .handled
        })
        .task(id: attempt) {
            do {
                failure = nil
                if let preview = viewModel.purchasesProvider as? CustomerCenterPreviewProvider,
                   let offering = viewModel.offering {
                    customVariables = await preview.previewCustomVariables()
                    promoEligible = await preview.previewPromotionalOfferEligibility()
                    workflow = try await preview.previewWorkflow(for: offering)
                }
                try Task.checkCancellation()
                loaded = true
            } catch is CancellationError {
            } catch {
                failure = error.localizedDescription
            }
        }
    }
    private func injectedPaywall(provider: CustomerCenterPreviewProvider, offering: Offering) -> some View {
        var configuration = PaywallViewConfiguration(
            offering: workflow?.initialOffering ?? offering,
            displayCloseButton: true,
            introEligibility: TrialOrIntroEligibilityChecker { packages in
                Dictionary(uniqueKeysWithValues: packages.map { ($0, .eligible) })
            },
            purchaseHandler: .customerCenterPreview(
                provider: provider,
                performPurchase: viewModel.performPurchase(packageToPurchase:),
                performRestore: viewModel.performRestore
            ),
            promoOfferCache: .simulated(if: promoEligible)
        )
        configuration.injectedWorkflowContext = workflow
        return PaywallView(configuration: configuration)
            .onRequestedDismissal { viewModel.hidePaywall() }
            .paywallSource(.customerCenter)
    }

}
#endif
