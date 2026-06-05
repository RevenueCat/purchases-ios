//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+ExitOfferPresentation.swift

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS)

/// Single owner of the exit-offer lifecycle (sourcing, state, present/dismiss/track), so present
/// functions don't each re-implement it.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class ExitOfferPresenter: ObservableObject {

    /// Resolved exit offer for the current step (or legacy prefetch).
    @Published private var exitOfferOffering: Offering?

    /// The exit offer currently being presented.
    @Published private var presentedExitOffer: Offering?

    private let purchaseHandler: PurchaseHandler

    init(purchaseHandler: PurchaseHandler) {
        self.purchaseHandler = purchaseHandler
    }

    var isPresentingExitOffer: Bool {
        self.presentedExitOffer != nil
    }

    /// Written by `WorkflowPaywallView` via the environment. Primary path; the preference is a fallback.
    var workflowBinding: Binding<Offering?> {
        Binding(
            get: { [weak self] in self?.exitOfferOffering },
            set: { [weak self] in self?.exitOfferOffering = $0 }
        )
    }

    /// Drives the exit-offer sheet/cover.
    var presentedBinding: Binding<Offering?> {
        Binding(
            get: { [weak self] in self?.presentedExitOffer },
            set: { [weak self] in self?.presentedExitOffer = $0 }
        )
    }

    /// Guarded so a late `nil` during the dismiss animation can't clear an already-presented offer.
    func updateFromWorkflowPreference(_ context: WorkflowExitOfferContext?) {
        guard ProcessInfo.processInfo.workflowsEndpointEnabled else { return }
        guard context != nil || self.presentedExitOffer == nil else { return }
        self.exitOfferOffering = context?.exitOfferOffering
    }

    /// Legacy offering-level prefetch, used only when workflows are disabled.
    func prefetchLegacyExitOffer(resolveOffering: () async -> Offering?) async {
        guard !ProcessInfo.processInfo.workflowsEndpointEnabled else { return }
        guard let offering = await resolveOffering() else { return }
        self.exitOfferOffering = await ExitOfferHelper.fetchValidExitOffer(for: offering)
    }

    /// Presents the exit offer if available. Returns `true` if it took over (caller shouldn't dismiss).
    @discardableResult
    func presentIfAvailable() -> Bool {
        guard self.presentedExitOffer == nil else { return true }
        guard let offering = self.exitOfferOffering else { return false }

        Logger.debug(Strings.presentingExitOffer(offering.identifier))
        self.purchaseHandler.trackExitOffer(
            exitOfferType: .dismiss,
            exitOfferingIdentifier: offering.identifier
        )
        self.presentedExitOffer = offering
        return true
    }

    /// Dismisses the presented exit offer (fires the sheet's `onDismiss`, which calls `reset()`).
    func dismissPresentedExitOffer() {
        self.presentedExitOffer = nil
    }

    func reset() {
        self.presentedExitOffer = nil
        self.exitOfferOffering = nil
        self.purchaseHandler.resetForNewSession()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
extension View {

    /// Sources the workflow exit offer onto the presenter. Apply to the main paywall view (keeps the
    /// binding/preference off the sheet boundary).
    func workflowExitOfferSource(
        presenter: ExitOfferPresenter,
        resolveLegacyOffering: @escaping () async -> Offering?
    ) -> some View {
        self
            .environment(\.workflowExitOfferOfferingBinding, presenter.workflowBinding)
            .onPreferenceChange(WorkflowExitOfferPreferenceKey.self) { context in
                presenter.updateFromWorkflowPreference(context)
            }
            .task {
                await presenter.prefetchLegacyExitOffer(resolveOffering: resolveLegacyOffering)
            }
    }

    /// Presents the exit offer as a sibling sheet/cover (after the main paywall dismisses, not nested).
    func exitOfferSheet<ExitOfferView: View>(
        presenter: ExitOfferPresenter,
        presentationMode: PaywallPresentationMode,
        onDismiss: (() -> Void)?,
        @ViewBuilder makeExitOfferView: @escaping (Offering) -> ExitOfferView
    ) -> some View {
        let handleDismiss: () -> Void = {
            presenter.reset()
            onDismiss?()
        }

        return Group {
            switch presentationMode {
            case .sheet:
                self.sheet(item: presenter.presentedBinding, onDismiss: handleDismiss) { offering in
                    makeExitOfferView(offering)
                    #if targetEnvironment(macCatalyst) || os(macOS)
                        .frame(minHeight: 667)
                    #endif
                }
            #if !os(macOS)
            case .fullScreen:
                self.fullScreenCover(item: presenter.presentedBinding, onDismiss: handleDismiss) { offering in
                    makeExitOfferView(offering)
                }
            #endif
            }
        }
    }

}

#endif
