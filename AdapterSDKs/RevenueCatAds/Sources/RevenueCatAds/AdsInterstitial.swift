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
/// Load it, then present it once. After it is dismissed (or fails to load) it can be loaded again.
@available(iOS 15.0, *)
@MainActor
@_spi(Experimental) public final class AdsInterstitial {

    enum State: Equatable {

        case idle
        case loading
        case loaded
        case presenting
        case presented

    }

    /// Identifies the ad slot on
    public let placementID: String

    /// Held weakly.
    public weak var delegate: AdsInterstitialDelegate?

    /// Whether the ad is loaded and can be presented.
    public var isReady: Bool {
        return self.state == .loaded && self.unit?.isReady == true
    }

    private(set) var state: State = .idle

    private let moduleProvider: () -> AdModule?
    private let tracker: InterstitialEventTracker
    private var unit: AdModuleInterstitial?
    private var impressionID = ""
    private var loadContinuation: CheckedContinuation<Void, Error>?
    private var impressionRecorded = false

    /// Creates an interstitial for the given placement. Requires ``RCAds/configure(with:)`` before ``load()``.
    public convenience init(placementID: String) {
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

    /// Loads an ad. ``AdsInterstitialDelegate`` is notified as well.
    ///
    /// - Throws: ``AdsError``.
    public func load() async throws {
        switch self.state {
        case .loading, .presenting, .presented:
            let error = AdsError(code: .invalidState, message: "Cannot load while the ad is \(self.state).")
            self.delegate?.interstitial(self, didFailWithError: error)
            throw error
        case .idle, .loaded:
            break
        }

        guard let module = self.moduleProvider() else {
            let error = AdsError(code: .notConfigured, message: "Call RCAds.configure(with:) before loading ads.")
            self.delegate?.interstitial(self, didFailWithError: error)
            throw error
        }

        let unit = module.makeInterstitial(placementID: self.placementID)
        unit.onEvent = { [weak self] event in self?.handle(event) }
        self.unit = unit
        self.impressionID = UUID().uuidString
        self.state = .loading
        self.impressionRecorded = false

        try await withCheckedThrowingContinuation { continuation in
            self.loadContinuation = continuation
            unit.load()
        }
    }

    /// Loads an ad, calling `completion` with `nil` on success. ``AdsInterstitialDelegate`` is notified as well.
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
    /// ``AdsInterstitialDelegate/interstitial(_:didFailWithError:)`` with ``AdsError/Code/notReady``.
    public func present(from viewController: UIViewController) {
        guard self.isReady, let unit = self.unit else {
            self.delegate?.interstitial(
                self,
                didFailWithError: AdsError(code: .notReady, message: "The ad is not loaded.")
            )
            return
        }

        self.state = .presenting
        unit.show(from: viewController)
    }

    private func handle(_ event: AdModuleEvent) {
        switch event {
        case .loaded, .failedToLoad:
            self.handleLoadEvent(event)
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
            self.delegate?.interstitialDidLoad(self)
        case let .failedToLoad(error):
            self.state = .idle
            self.unit = nil
            self.resumeLoad(with: .failure(error))
            self.delegate?.interstitial(self, didFailWithError: error)
        case .presented, .impression, .clicked, .dismissed:
            break
        }
    }

    private func handlePresentationEvent(_ event: AdModuleEvent) {
        guard let unit = self.unit else { return }

        switch (event, self.state) {
        case (.presented, .presenting):
            self.state = .presented
            self.tracker.track(event, unit: unit, impressionID: self.impressionID)
            self.delegate?.interstitialDidPresent(self)
        case (.impression, .presented) where !self.impressionRecorded:
            self.impressionRecorded = true
            self.tracker.track(event, unit: unit, impressionID: self.impressionID)
            self.delegate?.interstitialDidRecordImpression(self)
        case (.clicked, .presented):
            self.tracker.track(event, unit: unit, impressionID: self.impressionID)
            self.delegate?.interstitialDidRecordClick(self)
        case (.dismissed, .presenting), (.dismissed, .presented):
            self.state = .idle
            self.unit = nil
            self.delegate?.interstitialDidDismiss(self)
        default:
            break
        }
    }

    private func resumeLoad(with result: Result<Void, Error>) {
        let continuation = self.loadContinuation
        self.loadContinuation = nil
        continuation?.resume(with: result)
    }

}

#endif
