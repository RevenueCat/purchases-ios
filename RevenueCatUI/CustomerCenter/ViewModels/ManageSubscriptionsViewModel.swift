//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsViewModel.swift
//
//
//  Created by Cesar de la Vega on 27/5/24.
//

import Foundation
import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class ManageSubscriptionsViewModel: ObservableObject {

    let screen: CustomerCenterConfigData.Screen

    @Published
    var showRestoreAlert: Bool = false
    @Published
    var feedbackSurveyData: FeedbackSurveyData?
    @Published
    var loadingPath: CustomerCenterConfigData.HelpPath?
    @Published
    var promotionalOfferData: PromotionalOfferData?
    @Published
    var inAppBrowserURL: IdentifiableURL?
    @Published
    var state: CustomerCenterViewState {
        didSet {
            if case let .error(stateError) = state {
                self.error = stateError
            }
        }
    }

    var isLoaded: Bool {
        return state != .notLoaded
    }

    @Published
    private(set) var subscriptionInformation: SubscriptionInformation?
    @Published
    private(set) var refundRequestStatus: RefundRequestStatus?

    private var purchasesProvider: ManageSubscriptionsPurchaseType
    private let loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType
    private let customerCenterActionHandler: CustomerCenterActionHandler?
    private var error: Error?

    init(screen: CustomerCenterConfigData.Screen,
         customerCenterActionHandler: CustomerCenterActionHandler?,
         purchasesProvider: ManageSubscriptionsPurchaseType = ManageSubscriptionPurchases(),
         loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType? = nil) {
        self.screen = screen
        self.purchasesProvider = purchasesProvider
        self.customerCenterActionHandler = customerCenterActionHandler
        self.loadPromotionalOfferUseCase = loadPromotionalOfferUseCase ?? LoadPromotionalOfferUseCase()
        self.state = .notLoaded
    }

    init(screen: CustomerCenterConfigData.Screen,
         subscriptionInformation: SubscriptionInformation,
         customerCenterActionHandler: CustomerCenterActionHandler?,
         refundRequestStatus: RefundRequestStatus? = nil) {
        self.screen = screen
        self.subscriptionInformation = subscriptionInformation
        self.purchasesProvider = ManageSubscriptionPurchases()
        self.refundRequestStatus = refundRequestStatus
        self.customerCenterActionHandler = customerCenterActionHandler
        self.loadPromotionalOfferUseCase = LoadPromotionalOfferUseCase()
        state = .success
    }

    func loadScreen() async {
        do {
            try await loadSubscriptionInformation()
            self.state = .success
        } catch {
            self.state = .error(error)
        }
    }

    private func loadSubscriptionInformation() async throws {
        let customerInfo = try await purchasesProvider.customerInfo()

        // Find earliest expiring subscription
        guard let earliestProductId =
                customerInfo.activeSubscriptions.compactMap({ productId -> (String, Date)? in
                    guard let expirationDate = customerInfo.expirationDate(forProductIdentifier: productId) else {
                        return nil
                    }
                    return (productId, expirationDate)
                })
            .sorted(by: { $0.1 < $1.1 })
            .first?
            .0
        else {
            // If no subscriptions found, check for lifetime purchases
            if let firstNonSub = customerInfo.nonSubscriptions.first,
               let entitlement = customerInfo.entitlements.active.values.first,
               let product = await purchasesProvider.products([firstNonSub.productIdentifier]).first {
                let subscriptionInformation = SubscriptionInformation(entitlement: entitlement,
                                                                      subscribedProduct: product)
                self.subscriptionInformation = subscriptionInformation
                return
            }
            Logger.warning(Strings.could_not_find_subscription_information)
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }

        guard let product = await purchasesProvider.products([earliestProductId]).first else {
            Logger.warning(Strings.could_not_find_subscription_information)
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }

        // If we find a matching entitlement, use it. Otherwise, just use the product
        if let entitlement = customerInfo.entitlements.active.values.first(where: {
            $0.productIdentifier == earliestProductId
        }) {
            let subscriptionInformation = SubscriptionInformation(entitlement: entitlement,
                                                                  subscribedProduct: product)
            self.subscriptionInformation = subscriptionInformation
        } else {
            let expirationDate = customerInfo.expirationDate(forProductIdentifier: product.productIdentifier)
            let subscriptionInformation = SubscriptionInformation(product: product,
                                                                  expirationDate: expirationDate)
            self.subscriptionInformation = subscriptionInformation
        }
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    func determineFlow(for path: CustomerCenterConfigData.HelpPath) async {
        switch path.detail {
        case let .feedbackSurvey(feedbackSurvey):
            self.feedbackSurveyData = FeedbackSurveyData(configuration: feedbackSurvey) { [weak self] in
                Task {
                    await self?.onPathSelected(path: path)
                }
            }
        case let .promotionalOffer(promotionalOffer):
            if promotionalOffer.eligible {
                self.loadingPath = path
                let result = await loadPromotionalOfferUseCase.execute(promoOfferDetails: promotionalOffer)
                switch result {
                case .success(let promotionalOfferData):
                    self.promotionalOfferData = promotionalOfferData
                case .failure:
                    await self.onPathSelected(path: path)
                    self.loadingPath = nil
                }
            } else {
                await self.onPathSelected(path: path)
            }

        default:
            await self.onPathSelected(path: path)
        }
    }

    func handleSheetDismiss() async {
        if let loadingPath = loadingPath {
            await self.onPathSelected(path: loadingPath)
            self.loadingPath = nil
        }
    }

    func onDismissInAppBrowser() {
        self.inAppBrowserURL = nil
    }
#endif

}

struct IdentifiableURL: Identifiable {

    var id: String {
        return url.absoluteString
    }

    let url: URL

}

// MARK: - Promotional Offer Sheet Dismissal Handling
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension ManageSubscriptionsViewModel {

    /// Function responsible for handling the user's action on the PromotionalOfferView
    func handleDismissPromotionalOfferView(_ userAction: PromotionalOfferViewAction) async {
        // Clear the promotional offer data to dismiss the sheet
        self.promotionalOfferData = nil

        if userAction.shouldTerminateCurrentPathFlow {
            self.loadingPath = nil
        } else {
            if let loadingPath = loadingPath {
                await self.onPathSelected(path: loadingPath)
                self.loadingPath = nil
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension ManageSubscriptionsViewModel {

#if os(iOS) || targetEnvironment(macCatalyst)
    // swiftlint:disable:next cyclomatic_complexity
    private func onPathSelected(path: CustomerCenterConfigData.HelpPath) async {
        switch path.type {
        case .missingPurchase:
            self.showRestoreAlert = true
        case .refundRequest:
            do {
                guard let subscriptionInformation = self.subscriptionInformation else { return }
                let productId = subscriptionInformation.productIdentifier
                self.customerCenterActionHandler?(.refundRequestStarted(productId))
                let status = try await self.purchasesProvider.beginRefundRequest(forProduct: productId)
                self.refundRequestStatus = status
                self.customerCenterActionHandler?(.refundRequestCompleted(status))
            } catch {
                self.refundRequestStatus = .error
                self.customerCenterActionHandler?(.refundRequestCompleted(.error))
            }
        case .changePlans, .cancel:
            do {
                self.customerCenterActionHandler?(.showingManageSubscriptions)
                try await purchasesProvider.showManageSubscriptions()
            } catch {
                self.state = .error(error)
            }
        case .customUrl:
            guard let url = path.url,
                let openMethod = path.openMethod else {
                Logger.warning("Found a custom URL path without a URL or open method. Ignoring tap.")
                return
            }
            switch openMethod {
            case .external:
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            case .inApp:
                self.inAppBrowserURL = .init(url: url)
            }
        default:
            break
        }
    }
#endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private final class ManageSubscriptionPurchases: ManageSubscriptionsPurchaseType {

    func beginRefundRequest(forProduct productID: String) async throws -> RevenueCat.RefundRequestStatus {
        try await Purchases.shared.beginRefundRequest(forProduct: productID)
    }

    func showManageSubscriptions() async throws {
        try await Purchases.shared.showManageSubscriptions()
    }

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        try await Purchases.shared.customerInfo()
    }

    func products(_ productIdentifiers: [String]) async -> [StoreProduct] {
        await Purchases.shared.products(productIdentifiers)
    }

}

#endif
