//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BaseManageSubscriptionViewModel.swift
//
//  Created by Facundo Menzella on 5/5/25.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class BaseManageSubscriptionViewModel: ObservableObject {

    let screen: CustomerCenterConfigData.Screen

    var relevantPathsForPurchase: [CustomerCenterConfigData.HelpPath] {
        paths.relevantPaths(for: purchaseInformation, allowMissingPurchase: allowMissingPurchase)
    }

    /// Used to exclude .missingPurchase path
    ///
    /// If the detail screen is the root of the stack, then we should show it. Otherwise, it should be excluded
    var allowMissingPurchase: Bool {
        false
    }

    @Published
    var showAllPurchases = false

    @Published
    var showRestoreAlert: Bool = false

    @Published
    var restoreAlertType: RestorePurchasesAlertViewModel.AlertType

    @Published
    var feedbackSurveyData: FeedbackSurveyData?

    @Published
    var loadingPath: CustomerCenterConfigData.HelpPath?

    @Published
    var promotionalOfferData: PromotionalOfferData?

    @Published
    var inAppBrowserURL: IdentifiableURL?

    let actionWrapper: CustomerCenterActionWrapper

    @Published
    var purchaseInformation: PurchaseInformation?

    @Published
    var showAllInAppCurrenciesScreen: Bool = false

    @Published
    var showCreateTicket: Bool = false

    @Published
    private(set) var refundRequestStatus: RefundRequestStatus?

    private var error: Error?
    private let loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType
    let paths: [CustomerCenterConfigData.HelpPath]
    private(set) var purchasesProvider: CustomerCenterPurchasesType

    init(
        screen: CustomerCenterConfigData.Screen,
        actionWrapper: CustomerCenterActionWrapper,
        purchaseInformation: PurchaseInformation? = nil,
        refundRequestStatus: RefundRequestStatus? = nil,
        purchasesProvider: CustomerCenterPurchasesType,
        loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType? = nil) {
            self.screen = screen
            self.paths = screen.supportedPaths
            self.purchaseInformation = purchaseInformation
            self.purchasesProvider = purchasesProvider
            self.refundRequestStatus = refundRequestStatus
            self.actionWrapper = actionWrapper
            self.loadPromotionalOfferUseCase = loadPromotionalOfferUseCase
            ?? LoadPromotionalOfferUseCase(purchasesProvider: purchasesProvider)
            self.restoreAlertType = .loading
        }

#if os(iOS) || targetEnvironment(macCatalyst)
    func handleHelpPath(_ path: CustomerCenterConfigData.HelpPath, withActiveProductId: String? = nil) async {
        if let action = path.asAction() {
            self.actionWrapper.handleAction(.buttonTapped(action: action))
        }

        switch path.detail {
        case let .feedbackSurvey(feedbackSurvey):
            self.feedbackSurveyData = FeedbackSurveyData(
                productIdentifier: purchaseInformation?.productIdentifier,
                configuration: feedbackSurvey,
                path: path) { [weak self] in
                    Task {
                        await self?.onPathSelected(path: path)
                    }
                }

        case let .promotionalOffer(promotionalOffer) where purchaseInformation?.store == .appStore:
            if promotionalOffer.eligible, let productIdentifier = purchaseInformation?.productIdentifier {
                self.loadingPath = path
                let result = await loadPromotionalOfferUseCase.execute(
                    promoOfferDetails: promotionalOffer,
                    forProductId: productIdentifier
                )
                switch result {
                case .success(let promotionalOfferData):
                    self.promotionalOfferData = promotionalOfferData
                case .failure:
                    await self.onPathSelected(path: path)
                    self.loadingPath = nil
                }
            } else {
                Logger.debug(Strings.promo_offer_not_eligible_for_product(
                    promotionalOffer.iosOfferId, withActiveProductId ?? ""
                ))
                await self.onPathSelected(path: path)
            }

        default:
            await self.onPathSelected(path: path)
        }
    }

    func onDismissPromotionalOffer(action: PromotionalOfferViewAction) {
        self.promotionalOfferData = nil
        defer {
            self.loadingPath = nil
        }

        if let path = self.loadingPath,
           !action.shouldTerminateCurrentPathFlow {
            Task.detached(priority: .userInitiated) { @MainActor in
                await self.onPathSelected(path: path)
            }
        }
    }

    func onDismissInAppBrowser() {
        self.inAppBrowserURL = nil
    }

    func displayAllInAppCurrenciesScreen() {
        self.showAllInAppCurrenciesScreen = true
    }

#endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension BaseManageSubscriptionViewModel {

#if os(iOS) || targetEnvironment(macCatalyst)
    private func onPathSelected(path: CustomerCenterConfigData.HelpPath) async {
        switch path.type {
        case .missingPurchase:
            self.showRestoreAlert = true

        case .refundRequest:
            await handleRefundRequest()

        case .cancel where purchaseInformation?.store != .appStore:
            handleNonAppStoreCancel()

        case .changePlans:
            self.actionWrapper.handleAction(.showingChangePlans(purchaseInformation?.subscriptionGroupID))

        case .cancel:
            self.actionWrapper.handleAction(.showingManageSubscriptions)

        case .customUrl:
            handleCustomUrl(path: path)

        case .customAction:
            guard let actionIdentifier = path.customActionIdentifier else {
                return
            }
            self.actionWrapper.handleAction(
                .customActionSelected(
                    CustomActionData(
                        actionIdentifier: actionIdentifier,
                        purchaseIdentifier: purchaseInformation?.productIdentifier
                    )
                )
            )

        default:
            break
        }
    }

    private func handleRefundRequest() async {
        guard let purchaseInformation = self.purchaseInformation else { return }
        let productId = purchaseInformation.productIdentifier
        do {
            self.actionWrapper.handleAction(.refundRequestStarted(productId))

            let status = try await self.purchasesProvider.beginRefundRequest(forProduct: productId)
            self.refundRequestStatus = status
            self.actionWrapper.handleAction(.refundRequestCompleted(productId, status))
        } catch {
            self.refundRequestStatus = .error
            self.actionWrapper.handleAction(.refundRequestCompleted(productId, .error))
        }
    }

    private func handleNonAppStoreCancel() {
        if let url = purchaseInformation?.managementURL {
            self.inAppBrowserURL = IdentifiableURL(url: url)
        }
    }

    private func handleCustomUrl(path: CustomerCenterConfigData.HelpPath) {
        guard let url = path.url,
              let openMethod = path.openMethod else {
            Logger.warning("Found a custom URL path without a URL or open method. Ignoring tap.")
            return
        }
        switch openMethod {
        case .external,
            _ where !url.isWebLink:
            URLUtilities.openURLIfNotAppExtension(url)
        case .inApp:
            self.inAppBrowserURL = .init(url: url)
        @unknown default:
            Logger.warning(Strings.could_not_determine_type_of_custom_url)
            URLUtilities.openURLIfNotAppExtension(url)
        }
    }

#endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension BaseManageSubscriptionViewModel {

    var purchaseSubscriptionGroupID: String? {
        purchaseInformation?.subscriptionGroupID
    }

    var changePlanProductIDs: [String] {
        purchaseInformation?
            .changePlan
            .map { $0.products.filter { $0.selected }.map(\.productId) } ?? []
    }
}

private extension CustomerCenterConfigData.Screen {

    var supportedPaths: [CustomerCenterConfigData.HelpPath] {
        return self.paths.filter { path in
            return path.type != .unknown
        }
    }

}

#endif
