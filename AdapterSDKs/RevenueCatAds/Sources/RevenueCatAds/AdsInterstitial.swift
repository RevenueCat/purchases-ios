//
//  AdsInterstitial.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(PrebidMobile)
import UIKit

/// A full-screen interstitial ad served by RevenueCat.
///
/// Load it, then present it once. After it is dismissed (or fails to load, or expires) it can be loaded again.
@available(iOS 15.0, *)
@MainActor
@_spi(Experimental) public final class AdsInterstitial {

    enum State: Equatable {

        case idle
        case loading
        case loaded
        case presenting
        /// The underlying SDK reported presenting; UIKit's answer is checked on the next run loop turn.
        case confirmingPresentation
        case presented

    }

    /// Identifies where the ad is shown in your app. RevenueCat uses it for reporting, so keep it stable.
    public let placementID: String

    /// Receives the ad's presentation events (presented, impression, click, dismissal, expiry, failures).
    /// Load results come from ``load()`` itself. Held weakly.
    public weak var delegate: AdsInterstitialDelegate?

    /// Whether the ad is loaded and can be presented.
    public var isReady: Bool {
        return self.state == .loaded && self.unit?.isReady == true
    }

    private(set) var state: State = .idle

    private let moduleProvider: () -> AdModule?
    private let tracker: InterstitialEventTracker
    private var unit: AdModuleInterstitial?
    private var retainedWhilePresenting: AdsInterstitial?
    private weak var presenter: UIViewController?
    private var impressionID = ""
    private var loadContinuation: CheckedContinuation<Void, Error>?
    private var impressionRecorded = false
    private var impressionPending = false

    /// Creates an interstitial for the given placement. Requires ``RCAds/configure(with:)`` before ``load()``.
    public convenience init(placementID: String) { // swiftlint:disable:this no_new_public_inits
        self.init(placementID: placementID, moduleProvider: { RCAds.module })
    }

    init(
        placementID: String,
        moduleProvider: @escaping () -> AdModule?,
        tracking: AdTracking = PurchasesAdTracking()
    ) {
        self.placementID = placementID
        self.moduleProvider = moduleProvider
        self.tracker = InterstitialEventTracker(placementID: placementID, tracking: tracking)
    }

    /// Loads an ad. Returns immediately if an ad is already loaded. Calling it while a load is in progress or
    /// the ad is being presented throws ``AdsError/Code/invalidState``.
    ///
    /// - Throws: ``AdsError``.
    public func load() async throws {
        switch self.state {
        case .loading, .presenting, .confirmingPresentation, .presented:
            throw AdsError(code: .invalidState, message: "Cannot load while the ad is \(self.state).")
        case .loaded:
            return
        case .idle:
            break
        }

        guard let module = self.moduleProvider() else {
            throw AdsError(code: .notConfigured, message: "Call RCAds.configure(with:) before loading ads.")
        }

        let unit = module.makeInterstitial(placementID: self.placementID)
        // A replaced unit can still have callbacks in flight; they must not act on the new ad.
        unit.onEvent = { [weak self, weak unit] event in
            guard let self, let unit, unit === self.unit else { return }
            self.handle(event)
        }
        self.unit = unit
        self.impressionID = UUID().uuidString
        self.state = .loading
        self.impressionRecorded = false
        self.impressionPending = false

        try await withCheckedThrowingContinuation { continuation in
            self.loadContinuation = continuation
            unit.load()
        }
    }

    /// Loads an ad, calling `completion` with `nil` on success.
    public func load(completion: @escaping @MainActor (AdsError?) -> Void) {
        Task { @MainActor in
            do {
                try await self.load()
                completion(nil)
            } catch let error as AdsError {
                completion(error)
            } catch {
                completion(AdsError(code: .loadFailed, message: "The ad failed to load.", underlyingError: error))
            }
        }
    }

    /// Presents the loaded ad. If the ad is not ready, the delegate receives
    /// ``AdsInterstitialDelegate/interstitial(_:didFailToPresentWithError:)`` with ``AdsError/Code/notReady``.
    /// If `viewController` cannot present, it receives ``AdsError/Code/presentFailed``: the ad stays loaded
    /// when that is known up front, and is discarded when UIKit refuses the presentation, so load again.
    /// The instance stays alive until the ad is dismissed, so dropping your reference after this call is safe.
    public func present(from viewController: UIViewController) {
        guard self.isReady, let unit = self.unit else {
            self.delegate?.interstitial(
                self,
                didFailToPresentWithError: AdsError(code: .notReady, message: "The ad is not loaded.")
            )
            return
        }

        // Refusals that can be seen up front keep the ad; the rest are caught in `confirmPresentation`.
        if viewController.viewIfLoaded?.window == nil {
            self.failToPresent("The view controller is not in a window.")
            return
        }
        if viewController.presentedViewController != nil {
            self.failToPresent("The view controller is already presenting.")
            return
        }

        self.state = .presenting
        self.presenter = viewController
        self.retainedWhilePresenting = self
        unit.show(from: viewController)
    }

    private func handle(_ event: AdModuleEvent) {
        switch event {
        case .loaded, .failedToLoad:
            self.handleLoadEvent(event)
        case .expired:
            self.handleExpiry()
        case .presented, .impression, .clicked, .dismissed:
            self.handlePresentationEvent(event)
        }
    }

    private func handleLoadEvent(_ event: AdModuleEvent) {
        guard self.state == .loading, let unit = self.unit else { return }

        self.tracker.track(event, unit: unit, impressionID: self.impressionID)

        switch event {
        case .loaded:
            self.state = .loaded
            self.resumeLoad(with: .success(()))
        case let .failedToLoad(error):
            self.finish()
            self.resumeLoad(with: .failure(error))
        case .presented, .impression, .clicked, .dismissed, .expired:
            break
        }
    }

    private func handleExpiry() {
        guard self.state == .loaded else { return }

        self.finish()
        self.delegate?.interstitialDidExpire(self)
    }

    private func handlePresentationEvent(_ event: AdModuleEvent) {
        guard let unit = self.unit else { return }

        switch (event, self.state) {
        case (.presented, .presenting):
            // The underlying SDK reports this right before asking UIKit, and never reports a refusal.
            // UIKit records the presentation synchronously, so the next turn shows whether it happened.
            self.state = .confirmingPresentation
            DispatchQueue.main.async { [weak self, weak unit] in
                guard let self, let unit, unit === self.unit else { return }
                self.confirmPresentation(of: unit)
            }
        case (.impression, .confirmingPresentation):
            self.impressionPending = true
        case (.impression, .presented):
            self.recordImpression(unit: unit)
        case (.clicked, .presented):
            self.tracker.track(event, unit: unit, impressionID: self.impressionID)
            self.delegate?.interstitialDidRecordClick(self)
        case (.dismissed, .presenting), (.dismissed, .confirmingPresentation), (.dismissed, .presented):
            self.finish()
            self.delegate?.interstitialDidDismiss(self)
        default:
            break
        }
    }

    private func confirmPresentation(of unit: AdModuleInterstitial) {
        guard self.state == .confirmingPresentation else { return }

        guard self.presenter?.presentedViewController != nil else {
            // The underlying SDK has already consumed the ad, so it cannot be shown again.
            self.finish()
            self.failToPresent("The view controller refused the presentation.")
            return
        }

        self.state = .presented
        self.tracker.track(.presented, unit: unit, impressionID: self.impressionID)
        self.delegate?.interstitialDidPresent(self)
        if self.impressionPending {
            self.recordImpression(unit: unit)
        }
    }

    private func recordImpression(unit: AdModuleInterstitial) {
        guard !self.impressionRecorded else { return }

        self.impressionRecorded = true
        self.impressionPending = false
        self.tracker.track(.impression, unit: unit, impressionID: self.impressionID)
        self.delegate?.interstitialDidRecordImpression(self)
    }

    private func finish() {
        self.state = .idle
        self.unit = nil
        self.presenter = nil
        self.retainedWhilePresenting = nil
    }

    private func failToPresent(_ message: String) {
        self.delegate?.interstitial(self, didFailToPresentWithError: AdsError(code: .presentFailed, message: message))
    }

    private func resumeLoad(with result: Result<Void, Error>) {
        let continuation = self.loadContinuation
        self.loadContinuation = nil
        continuation?.resume(with: result)
    }

}

#endif
