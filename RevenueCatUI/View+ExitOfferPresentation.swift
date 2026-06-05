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

/// Owns the exit-offer lifecycle for a single paywall presentation: how the offer is *sourced*
/// (workflow step-aware, with a legacy offering-level fallback), the two pieces of state, and the
/// transitions between them.
///
/// This is the single home for logic each `present…` entry point used to re-implement. A present
/// function creates one and wires it via `workflowExitOfferSource` (onto the main paywall) and
/// `exitOfferSheet` (onto the presenting view).
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class ExitOfferPresenter: ObservableObject {

    /// The exit offer resolved for the current step (workflow) or prefetched (legacy). Updated as the
    /// user navigates; read at dismissal time.
    @Published private var exitOfferOffering: Offering?

    /// The exit offer currently being presented. Drives the sheet/cover.
    @Published private var presentedExitOffer: Offering?

    private let purchaseHandler: PurchaseHandler

    init(purchaseHandler: PurchaseHandler) {
        self.purchaseHandler = purchaseHandler
    }

    /// Whether an exit offer is currently being presented.
    var isPresentingExitOffer: Bool {
        self.presentedExitOffer != nil
    }

    /// Binding handed to `WorkflowPaywallView` (via the environment) so it can write the step-aware
    /// exit offer directly. This is the reliable path; the preference key below is a fallback.
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

    /// Workflow preference fallback. Mirrors the binding, but guarded so a final `nil` emitted during
    /// the dismiss animation can't clear the offer after it's already being presented.
    func updateFromWorkflowPreference(_ context: WorkflowExitOfferContext?) {
        guard ProcessInfo.processInfo.workflowsEndpointEnabled else { return }
        guard context != nil || self.presentedExitOffer == nil else { return }
        self.exitOfferOffering = context?.exitOfferOffering
    }

    /// Legacy offering-level prefetch, used only when the workflows endpoint is disabled.
    func prefetchLegacyExitOffer(resolveOffering: () async -> Offering?) async {
        guard !ProcessInfo.processInfo.workflowsEndpointEnabled else { return }
        guard let offering = await resolveOffering() else { return }
        self.exitOfferOffering = await ExitOfferHelper.fetchValidExitOffer(for: offering)
    }

    /// Presents the exit offer if one is available. Returns `true` if it took over (the caller should
    /// not dismiss), `false` if there's nothing to show (the caller should dismiss normally).
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

    /// Dismisses the presented exit offer (e.g. after a successful purchase/restore on it). Clearing
    /// `presentedExitOffer` fires the sheet's `onDismiss`, which calls `reset()`.
    func dismissPresentedExitOffer() {
        self.presentedExitOffer = nil
    }

    /// Tears down after the exit offer is dismissed (or when the offer should be discarded).
    func reset() {
        self.presentedExitOffer = nil
        self.exitOfferOffering = nil
        self.purchaseHandler.resetForNewSession()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
extension View {

    /// Sources the workflow exit offer onto the presenter. Apply to the *main* paywall view so the
    /// environment binding reaches `WorkflowPaywallView` and its preference is observed without
    /// crossing a sheet boundary.
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

    /// Attaches the exit-offer sheet/cover driven by the presenter. Apply to the *presenting* view
    /// (sibling of the main paywall presentation) so the exit offer shows after the main paywall
    /// dismisses, rather than nested inside it.
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
