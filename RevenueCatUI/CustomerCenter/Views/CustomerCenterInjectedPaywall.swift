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
struct CustomerCenterInjectedPaywall: View {
    let provider: CustomerCenterPreviewProvider
    let offering: Offering?
    let performPurchase: PerformPurchase
    let performRestore: PerformRestore
    let onClose: () -> Void

    private enum LoadState {
        case loading
        case loaded(WorkflowContext?, [String: CustomVariableValue], IntroEligibilityStatus, PaywallPromoOfferCache)
        case failed(String)
    }

    @State private var state: LoadState = .loading
    @State private var attempt = 0

    var body: some View {
        Group {
            switch state {
            case let .loaded(workflow, customVariables, introEligibility, promoOfferCache):
                if let offering {
                    injectedPaywall(
                        offering: offering,
                        workflow: workflow,
                        introEligibility: introEligibility,
                        promoOfferCache: promoOfferCache
                    )
                    .customPaywallVariables(customVariables)
                } else {
                    VStack {
                        Text("The configured preview offering is unavailable.")
                        Button("Close", action: onClose)
                    }
                }
            case let .failed(message):
                VStack {
                    Text(message)
                    Button("Retry") { attempt += 1 }
                    Button("Close", action: onClose)
                }
            case .loading:
                ProgressView()
            }
        }
        .task(id: attempt) {
            state = .loading
            do {
                let customVariables = await provider.previewCustomVariables()
                let introEligible = await provider.previewIntroOfferEligibility()
                let promoEligible = await provider.previewPromotionalOfferEligibility()
                let workflow: WorkflowContext?
                if let offering {
                    workflow = try await provider.previewWorkflow(for: offering)
                } else {
                    workflow = nil
                }
                try Task.checkCancellation()
                state = .loaded(
                    workflow,
                    customVariables,
                    introEligible ? .eligible : .ineligible,
                    PaywallPromoOfferCache(simulateEligible: promoEligible)
                )
            } catch is CancellationError {
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    @MainActor
    private func injectedPaywall(
        offering: Offering,
        workflow: WorkflowContext?,
        introEligibility: IntroEligibilityStatus,
        promoOfferCache: PaywallPromoOfferCache
    ) -> some View {
        var configuration = PaywallViewConfiguration(
            offering: workflow?.initialOffering ?? offering,
            displayCloseButton: true,
            introEligibility: .producing(eligibility: introEligibility),
            purchaseHandler: .customerCenterPreview(
                provider: provider,
                performPurchase: performPurchase,
                performRestore: performRestore
            ),
            promoOfferCache: promoOfferCache
        )
        configuration.injectedWorkflowContext = workflow
        return PaywallView(configuration: configuration)
            .onRequestedDismissal { onClose() }
            .paywallSource(.customerCenter)
    }

}
#endif
