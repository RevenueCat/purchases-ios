//
//  PaywallsResponse.swift
//
//
//  Created by Nacho Soto on 12/13/23.
//

import Foundation

import RevenueCat

public struct PaywallsResponse: Sendable {

    public var all: [Paywall] = []

}

extension PaywallsResponse {

    public struct Paywall: Sendable {

        public var data: PaywallData
        public var offeringID: String

    }

}

extension PaywallsResponse.Paywall: Hashable {}

extension PaywallsResponse.Paywall: Identifiable {

    public var id: String {
        return self.offeringID
    }

}

extension PaywallsResponse.Paywall: Decodable {

    private enum CodingKeys: String, CodingKey {

        case offeringId

    }

    public init(from decoder: Decoder) throws {
        let paywallContainer = try decoder.singleValueContainer()
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.data = try paywallContainer.decode(PaywallData.self)
        self.offeringID = try container.decode(String.self, forKey: .offeringId)
    }

}

extension PaywallsResponse: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        self.all = try container.decode([Paywall].self)
    }

}

extension PaywallsResponse.Paywall {

    func convertToRevenueCatPaywall(with offering: OfferingsResponse.Offering) -> RevenueCat.Offering {
        return .init(
            identifier: offering.identifier,
            serverDescription: offering.displayName,
            paywall: self.data,
            availablePackages: self.data.config.packages.map {
                let type = Package.packageType(from: $0)

                let introDiscount = TestStoreProductDiscount(identifier: "intro",
                                                             price: 0,
                                                             localizedPriceString: "$0.00",
                                                             paymentMode: .freeTrial,
                                                             subscriptionPeriod: .init(value: 1, unit: .week),
                                                             numberOfPeriods: 1,
                                                             type: .introductory
                )

                return .init(
                    identifier: $0,
                    packageType: type,
                    // TODO: improve this to depend on package type
                    storeProduct: TestStoreProduct(
                        localizedTitle: $0,
                        price: 1.99,
                        localizedPriceString: "$39.99",
                        productIdentifier: "com.revenuecat.test_product",
                        productType: .autoRenewableSubscription,
                        localizedDescription: $0,
                        subscriptionPeriod: type.subscriptionPeriod,
                        introductoryDiscount: .init(
                            identifier: "intro",
                            price: 0,
                            localizedPriceString: "$0.00",
                            paymentMode: .freeTrial,
                            subscriptionPeriod: .init(value: 1, unit: .week),
                            numberOfPeriods: 1,
                            type: .introductory
                        )
                    ).toStoreProduct(),
                    offeringIdentifier: offering.identifier,
                    webCheckoutUrl: nil
                )
            },
            webCheckoutUrl: nil
        )
    }

}

private extension PackageType {

    var subscriptionPeriod: SubscriptionPeriod? {
        switch self {
        case .weekly: .init(value: 1, unit: .week)
        case .monthly: .init(value: 1, unit: .month)
        case .annual:  .init(value: 1, unit: .year)

        default: nil
        }
    }

}
