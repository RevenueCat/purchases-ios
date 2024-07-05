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
    var isShowingPromotionalOffer: Bool = false
    @Published
    var loadingPath: CustomerCenterConfigData.HelpPath?

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
    private(set) var refundRequestStatusMessage: String?

    var promotionalOffer: PromotionalOffer? {
        return promotionalOfferViewModel.promotionalOffer
    }

    var promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer? {
        return promotionalOfferViewModel.promoOfferDetails
    }

    var localization: CustomerCenterConfigData.Localization? {
        return promotionalOfferViewModel.localization
    }

    var product: StoreProduct? {
        return promotionalOfferViewModel.product
    }

    private var purchasesProvider: ManageSubscriptionsPurchaseType
    private var promotionalOfferViewModel: PromotionalOfferViewModel
    private let customerCenterActionHandler: CustomerCenterActionHandler?

    private var error: Error?

    convenience init(screen: CustomerCenterConfigData.Screen,
                     customerCenterActionHandler: CustomerCenterActionHandler?) {
        self.init(screen: screen,
                  purchasesProvider: ManageSubscriptionPurchases(),
                  customerCenterActionHandler: customerCenterActionHandler,
                  promotionalOfferViewModel: PromotionalOfferViewModel())
    }

    init(screen: CustomerCenterConfigData.Screen,
         purchasesProvider: ManageSubscriptionsPurchaseType,
         customerCenterActionHandler: CustomerCenterActionHandler?,
         promotionalOfferViewModel: PromotionalOfferViewModel) {
        self.state = .notLoaded
        self.screen = screen
        self.purchasesProvider = purchasesProvider
        self.customerCenterActionHandler = customerCenterActionHandler
        self.promotionalOfferViewModel = promotionalOfferViewModel
    }

    init(screen: CustomerCenterConfigData.Screen,
         subscriptionInformation: SubscriptionInformation,
         customerCenterActionHandler: CustomerCenterActionHandler?,
         refundRequestStatusMessage: String? = nil) {
        self.screen = screen
        self.subscriptionInformation = subscriptionInformation
        self.purchasesProvider = ManageSubscriptionPurchases()
        self.refundRequestStatusMessage = refundRequestStatusMessage
        self.customerCenterActionHandler = customerCenterActionHandler
        self.promotionalOfferViewModel = PromotionalOfferViewModel()
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

        // Pick the soonest expiring iOS App Store entitlement and accompanying product.
        guard let currentEntitlement = customerInfo.currentEntitlement(),
              let subscribedProduct = await purchasesProvider.products([currentEntitlement.productIdentifier]).first
        else {
            Logger.warning(Strings.could_not_find_subscription_information)
            throw CustomerCenterError.couldNotFindSubscriptionInformation
        }

        // swiftlint:disable:next todo
        // TODO: support non-consumables
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        self.subscriptionInformation = SubscriptionInformation(
            title: subscribedProduct.localizedTitle,
            durationTitle: subscribedProduct.subscriptionPeriod?.durationTitle ?? "",
            price: subscribedProduct.localizedPriceString,
            expirationDateString: currentEntitlement.expirationDate.map { dateFormatter.string(from: $0) } ?? nil,
            willRenew: currentEntitlement.willRenew,
            productIdentifier: currentEntitlement.productIdentifier,
            active: currentEntitlement.isActive
        )
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    func determineFlow(for path: CustomerCenterConfigData.HelpPath) async {
        switch path.detail {
        case let .feedbackSurvey(feedbackSurvey):
            self.feedbackSurveyData = FeedbackSurveyData(configuration: feedbackSurvey) { [weak self] in
                Task {
                    await self?.performAction(for: path)
                }
            }
        case let .promotionalOffer(promotionalOffer):
            self.loadingPath = path
            await promotionalOfferViewModel.loadPromo(promotionalOfferId: promotionalOffer.iosOfferId)
            self.isShowingPromotionalOffer = true
        default:
            await self.performAction(for: path)
        }
    }

    func handleSheetDismiss() async {
        if let loadingPath = loadingPath {
            await self.performAction(for: loadingPath)
            self.loadingPath = nil
        }
    }
#endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension ManageSubscriptionsViewModel {

#if os(iOS) || targetEnvironment(macCatalyst)
    private func performAction(for path: CustomerCenterConfigData.HelpPath) async {
        switch path.type {
        case .missingPurchase:
            self.showRestoreAlert = true
        case .refundRequest:
            do {
                guard let subscriptionInformation = self.subscriptionInformation else { return }
                let productId = subscriptionInformation.productIdentifier
                self.customerCenterActionHandler?(.refundRequestStarted(productId))
                let status = try await self.purchasesProvider.beginRefundRequest(forProduct: productId)
                self.customerCenterActionHandler?(.refundRequestCompleted(status))
                switch status {
                case .error:
                    self.refundRequestStatusMessage = String(localized: "Error when requesting refund, try again")
                case .success:
                    self.refundRequestStatusMessage = String(localized: "Refund granted successfully!")
                case .userCancelled:
                    self.refundRequestStatusMessage = String(localized: "Refund canceled")
                }
            } catch {
                self.customerCenterActionHandler?(.refundRequestCompleted(.error))
                self.refundRequestStatusMessage =
                String(localized: "An error occurred while processing the refund request.")
            }
        case .changePlans, .cancel:
            do {
                self.customerCenterActionHandler?(.showingManageSubscriptions)
                try await purchasesProvider.showManageSubscriptions()
            } catch {
                self.state = .error(error)
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension SubscriptionPeriod {

    var durationTitle: String {
        switch self.unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        default: return "Unknown"
        }
    }

}

#endif
