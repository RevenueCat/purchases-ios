//
//  PaywallsResponse.swift
//
//
//  Created by Nacho Soto on 12/13/23.
//

import Foundation

import RevenueCat

public struct PaywallsResponse {

    public var all: [Paywall]

}

extension PaywallsResponse {

    public struct Paywall {

        public var data: PaywallData
        public var offeringID: String

    }

}

// MARK: - Hashable

extension PaywallsResponse.Paywall: Hashable {}

// MARK: - Identifiable

extension PaywallsResponse.Paywall: Identifiable {

    public var id: String {
        return self.offeringID
    }

}

// MARK: - Decodable

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
