//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardedAdPromptModel.swift
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
import SwiftUI
import UIKit

@available(iOS 15.0, *)
@MainActor
protocol RewardedAdPromptPresentingAd: AnyObject {

    func enableRewardVerification()

    func disableRewardVerification()

    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (@MainActor () -> Void)?,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    )

    func present(
        from viewController: UIViewController?,
        userDidEarnRewardHandler: @escaping () -> Void
    )

}

@available(iOS 15.0, *)
@MainActor
protocol RewardedAdPromptAd: RewardedAdPromptPresentingAd {

    var adUnitID: String { get }

    func setTrackingFullScreenContentDelegate(_ delegate: GoogleMobileAds.FullScreenContentDelegate?)

}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedAd: RewardedAdPromptAd {}

@available(iOS 15.0, *)
extension GoogleMobileAds.RewardedInterstitialAd: RewardedAdPromptAd {}

@available(iOS 15.0, *)
@MainActor
struct RewardedAdPromptDependencies {

    let isPurchasesConfigured: () -> Bool
    let loadRewards: (String) async -> ConfiguredAdRewards?
    let trackPromptShown: (String, String?) -> Void
    let trackPromptAccepted: (String, String?) -> Void

    static var live: Self {
        return .init(
            isPurchasesConfigured: { Purchases.isConfigured },
            loadRewards: { adUnitID in
                await Purchases.shared.adRewards(forAdUnitId: adUnitID)
            },
            trackPromptShown: { adUnitID, placement in
                Purchases.shared.adTracker.trackRewardedAdPromptShown(.init(
                    mediatorName: .adMob,
                    placement: placement,
                    adUnitId: adUnitID
                ))
            },
            trackPromptAccepted: { adUnitID, placement in
                Purchases.shared.adTracker.trackRewardedAdPromptAccepted(.init(
                    mediatorName: .adMob,
                    placement: placement,
                    adUnitId: adUnitID
                ))
            }
        )
    }

}

@available(iOS 15.0, *)
extension EnvironmentValues {

    var rewardedAdPromptDependencies: RewardedAdPromptDependencies? {
        get { self[RewardedAdPromptDependenciesKey.self] }
        set { self[RewardedAdPromptDependenciesKey.self] = newValue }
    }

}

@available(iOS 15.0, *)
private struct RewardedAdPromptDependenciesKey: EnvironmentKey {

    static let defaultValue: RewardedAdPromptDependencies? = nil

}

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptModel: NSObject, ObservableObject {

    @Published private(set) var configuredRewards: ConfiguredAdRewards?
    @Published private(set) var hasAccepted = false

    var context: RewardedAdPromptContext? {
        return self.context(callbackDispatcherFactory: self.callbackDispatcherFactory)
    }

    func context(
        callbackDispatcherFactory: @escaping @MainActor () -> any RewardedAdPromptCallbackDispatching
    ) -> RewardedAdPromptContext? {
        guard !self.hasAccepted, self.dependencies.isPurchasesConfigured() else {
            return nil
        }

        return RewardedAdPromptContext(
            rewardConfiguration: self.configuredRewards,
            acceptAction: { [weak self] in
                self?.accept(callbackDispatcherFactory: callbackDispatcherFactory)
            }
        )
    }

    private let defaultSession: RewardedAdPromptSession
    private var session: RewardedAdPromptSession
    private let adUnitID: String
    private let placement: String?
    private let loadsRewardConfiguration: Bool
    private let rewardedAd: any RewardedAdPromptAd
    private let callbackDispatcherFactory: @MainActor () -> any RewardedAdPromptCallbackDispatching
    private let dependencies: RewardedAdPromptDependencies

    private weak var presentationAnchor: UIViewController?
    private var isLoadingRewards = false
    // AdMob delegates are weak. Keep dismissal handling alive independently of the SwiftUI view.
    private static let presentationDelegateStore = AssociatedObjectStore<RewardedAdPromptPresentationDelegate>()

    init(
        session: RewardedAdPromptSession?,
        ad rewardedAd: any RewardedAdPromptAd,
        placement: String?,
        loadsRewardConfiguration: Bool,
        callbackDispatcherFactory: @escaping @MainActor () -> any RewardedAdPromptCallbackDispatching,
        dependencies: RewardedAdPromptDependencies
    ) {
        let defaultSession = RewardedAdPromptSession()
        self.defaultSession = defaultSession
        self.session = session ?? defaultSession
        self.adUnitID = rewardedAd.adUnitID
        self.placement = placement
        self.loadsRewardConfiguration = loadsRewardConfiguration
        self.rewardedAd = rewardedAd
        self.callbackDispatcherFactory = callbackDispatcherFactory
        self.dependencies = dependencies
        super.init()
    }

    func loadRewardsIfNeeded() async {
        guard self.loadsRewardConfiguration,
              self.configuredRewards == nil,
              !self.hasAccepted,
              !self.isLoadingRewards else { return }
        guard self.dependencies.isPurchasesConfigured() else {
            Logger.warn(RewardedAdPromptStrings.purchases_not_configured)
            return
        }

        self.isLoadingRewards = true
        defer { self.isLoadingRewards = false }

        guard let configuredRewards = await self.dependencies.loadRewards(self.adUnitID) else {
            Logger.debug(RewardedAdPromptStrings.configured_rewards_unavailable(adUnitID: self.adUnitID))
            return
        }
        guard !self.hasAccepted else { return }

        self.configuredRewards = configuredRewards
    }

    func setPresentationAnchor(_ viewController: UIViewController) {
        self.presentationAnchor = viewController
    }

    func promptDidAppear() {
        self.trackAppearance(session: self.session, placement: self.placement)
    }

    func promptDidAppear(session: RewardedAdPromptSession?, placement: String?) {
        self.trackAppearance(session: session ?? self.defaultSession, placement: placement)
    }

    private func trackAppearance(session: RewardedAdPromptSession, placement: String?) {
        guard !self.hasAccepted else { return }
        self.session = session
        guard session.consumePromptShown(placement: placement) else { return }
        self.dependencies.trackPromptShown(self.adUnitID, placement)
    }

    private func accept(callbackDispatcherFactory: @MainActor () -> any RewardedAdPromptCallbackDispatching) {
        guard !self.hasAccepted, self.dependencies.isPurchasesConfigured() else { return }

        self.hasAccepted = true
        let placement = self.session.placementForAcceptance(fallback: self.placement)
        self.session.resetAfterAcceptance()
        let callbackDispatcher = callbackDispatcherFactory()

        self.dependencies.trackPromptAccepted(self.adUnitID, placement)
        guard let viewController = self.presentationAnchor?.rewardedAdPromptPresentationViewController else {
            callbackDispatcher.notPresented(.init(code: .presentationContextUnavailable, underlyingError: nil))
            return
        }

        let delegate = RewardedAdPromptPresentationDelegate(callbackDispatcher: callbackDispatcher)
        Self.presentationDelegateStore.set(delegate, for: self.rewardedAd)
        self.rewardedAd.setTrackingFullScreenContentDelegate(delegate)
        callbackDispatcher.present(self.rewardedAd, from: viewController)
    }

}

@available(iOS 15.0, *)
@MainActor
private final class RewardedAdPromptPresentationDelegate: NSObject, GoogleMobileAds.FullScreenContentDelegate {

    private let callbackDispatcher: any RewardedAdPromptCallbackDispatching

    init(callbackDispatcher: any RewardedAdPromptCallbackDispatching) {
        self.callbackDispatcher = callbackDispatcher
    }

    func adDidDismissFullScreenContent(_ presentingAd: any GoogleMobileAds.FullScreenPresentingAd) {
        self.callbackDispatcher.dismissed()
    }

    func ad(
        _ presentingAd: any GoogleMobileAds.FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: any Error
    ) {
        let promptError = RewardedAdPromptError(code: .adFailedToPresent, underlyingError: error)
        self.callbackDispatcher.notPresented(promptError)
    }

}

#endif
