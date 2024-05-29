//
//  ManageSubscriptionsViewModel.swift
//
//
//  Created by Cesar de la Vega on 27/5/24.
//

import Foundation
import RevenueCat

@available(iOS 15.0, *)
class ManageSubscriptionsViewModel: ObservableObject {

    var isLoaded: Bool {
        if case .notLoaded = state {
            return false
        }
        return true
    }

    @Published
    var subscriptionInformation: SubscriptionInformation?
    @Published
    var refundRequestStatus: String?
    @Published
    var configuration: CustomerCenterData?
    @Published var state: State {
        didSet {
            if case let .error(stateError) = state {
                self.error = stateError
            }
        }
    }

    private var error: Error?

    enum State {

        case notLoaded
        case success
        case error(Error)

    }

    init() {
        state = .notLoaded
    }

    init(configuration: CustomerCenterData) {
        state = .notLoaded
        self.configuration = configuration
    }

    init(configuration: CustomerCenterData, subscriptionInformation: SubscriptionInformation) {
        self.configuration = configuration
        self.subscriptionInformation = subscriptionInformation
        state = .success
    }

    func loadSubscriptionInformation() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            guard let currentEntitlementDict = customerInfo.entitlements.active.first,
                  let subscribedProductID = customerInfo.activeSubscriptions.first,
                  let subscribedProduct = await Purchases.shared.products([subscribedProductID]).first else {
                Logger.warning(Strings.could_not_find_subscription_information)
                self.state = .error(CustomerCenterError.couldNotFindSubscriptionInformation)
                return
            }
            let currentEntitlement = currentEntitlementDict.value

            self.subscriptionInformation = SubscriptionInformation(
                title: subscribedProduct.localizedTitle,
                duration: subscribedProduct.subscriptionPeriod?.durationTitle ?? "",
                price: subscribedProduct.localizedPriceString,
                nextRenewal: "\(String(describing: currentEntitlement.expirationDate!))",
                willRenew: currentEntitlement.willRenew,
                productIdentifier: subscribedProductID,
                active: currentEntitlement.isActive
            )
        } catch {
            self.state = .error(error)
        }
    }

}

@available(iOS 15.0, *)
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

    func periodTitle() -> String {
        let periodString = "\(self.value) \(self.durationTitle)"
        let pluralized = self.value > 1 ?  periodString + "s" : periodString
        return pluralized
    }

}
