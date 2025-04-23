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
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
final class ManageSubscriptionsViewModel: ObservableObject {

    let screen: CustomerCenterConfigData.Screen

    var relevantPathsForPurchase: [CustomerCenterConfigData.HelpPath] {
        paths.relevantPathsForPurchase(purchaseInformation)
    }

    @Published
    var showRestoreAlert: Bool = false

    @Published
    var restoreAlertType: RestorePurchasesAlertViewModel.AlertType

    @Published
    var showPurchases: Bool = false

    @Published var showBalances: Bool = false

    @Published
    var feedbackSurveyData: FeedbackSurveyData?

    @Published
    var loadingPath: CustomerCenterConfigData.HelpPath?

    @Published
    var promotionalOfferData: PromotionalOfferData?

    @Published
    var inAppBrowserURL: IdentifiableURL?

    @Published
    var virtualCurrencies: [String: RevenueCat.VirtualCurrencyInfo]

    @Published
    var state: CustomerCenterViewState {
        didSet {
            if case let .error(stateError) = state {
                self.error = stateError
            }
        }
    }

    let actionWrapper: CustomerCenterActionWrapper

    @Published
    private(set) var purchaseInformation: PurchaseInformation?

    @Published
    private(set) var refundRequestStatus: RefundRequestStatus?

    private var error: Error?
    private let loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType
    private let paths: [CustomerCenterConfigData.HelpPath]
    private(set) var purchasesProvider: CustomerCenterPurchasesType

    init(
        screen: CustomerCenterConfigData.Screen,
        actionWrapper: CustomerCenterActionWrapper,
        purchaseInformation: PurchaseInformation? = nil,
        refundRequestStatus: RefundRequestStatus? = nil,
        purchasesProvider: CustomerCenterPurchasesType,
        loadPromotionalOfferUseCase: LoadPromotionalOfferUseCaseType? = nil,
        virtualCurrencies: [String: RevenueCat.VirtualCurrencyInfo]) {
            self.screen = screen
            self.paths = screen.filteredPaths
            self.purchaseInformation = purchaseInformation
            self.purchasesProvider = purchasesProvider
            self.refundRequestStatus = refundRequestStatus
            self.actionWrapper = actionWrapper
            self.loadPromotionalOfferUseCase = loadPromotionalOfferUseCase
            ?? LoadPromotionalOfferUseCase(purchasesProvider: purchasesProvider)
            self.state = .success
            self.restoreAlertType = .loading
            self.virtualCurrencies = virtualCurrencies
        }

#if os(iOS) || targetEnvironment(macCatalyst)
    func determineFlow(for path: CustomerCenterConfigData.HelpPath, activeProductId: String? = nil) async {
        // Convert the path to an appropriate action using the extension
        if let action = path.asAction() {
            // Send the action through the action wrapper
            self.actionWrapper.handleAction(.buttonTapped(action: action))
        }

        switch path.detail {
        case let .feedbackSurvey(feedbackSurvey):
            self.feedbackSurveyData = FeedbackSurveyData(
                configuration: feedbackSurvey,
                path: path) { [weak self] in
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
                Logger.debug(Strings.promo_offer_not_eligible_for_product(
                    promotionalOffer.iosOfferId, activeProductId ?? ""
                ))
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
        switch userAction {
        case .successfullyRedeemedPromotionalOffer:
            self.actionWrapper.handleAction(.promotionalOfferSuccess)
        case .declinePromotionalOffer, .promotionalCodeRedemptionFailed:
            break
        }

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

        case .changePlans, .cancel:
            self.actionWrapper.handleAction(.showingManageSubscriptions)

        case .customUrl:
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

        default:
            break
        }
    }
#endif

}

private extension CustomerCenterConfigData.Screen {

    var filteredPaths: [CustomerCenterConfigData.HelpPath] {
        return self.paths.filter { path in
            return path.type != .unknown
        }
    }

}

private extension Array<CustomerCenterConfigData.HelpPath> {
    func relevantPathsForPurchase(
        _ purchaseInformation: PurchaseInformation?
    ) -> [CustomerCenterConfigData.HelpPath] {
        guard let purchaseInformation else {
            return self
        }

        return filter {
            // if it's cancel, it cannot be a lifetime subscription
            ($0.type != .cancel || !purchaseInformation.isLifetime) &&

            // if it's refundRequest, it cannot be free  nor within trial period
            ($0.type != .refundRequest || (purchaseInformation.price != .free && !purchaseInformation.isTrial)) &&

            // if it has a refundDuration, check it's still valid
            ($0.refundWindowDuration?.isWithin(purchaseInformation) ?? true)
        }
    }
}

private extension CustomerCenterConfigData.HelpPath.RefundWindowDuration {
    func isWithin(_ purchaseInformation: PurchaseInformation) -> Bool {
        switch self {
        case .forever:
            return true

        case let .duration(duration):
            return duration.isWithin(
                from: purchaseInformation.latestPurchaseDate,
                now: purchaseInformation.customerInfoRequestedDate
            )

        @unknown default:
            return true
        }
    }
}

private extension ISODuration {
    func isWithin(from startDate: Date?, now: Date) -> Bool {
        guard let startDate else {
            return true
        }

        var dateComponents = DateComponents()
        dateComponents.year = self.years
        dateComponents.month = self.months
        dateComponents.weekOfYear = self.weeks
        dateComponents.day = self.days
        dateComponents.hour = self.hours
        dateComponents.minute = self.minutes
        dateComponents.second = self.seconds

        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: dateComponents, to: startDate) ?? startDate

        return startDate < endDate && now <= endDate
    }
}

#endif
