//
//  OfferingsResponse.swift
//
//
//  Created by Nacho Soto on 12/13/23.
//

import Foundation

import RevenueCat

public struct OfferingsResponse: Sendable {

    public let all: [Offering]

}

extension OfferingsResponse {
    
    public struct Offering: Sendable {

        public let createdAt: Date
        public let displayName: String
        public let id: String
        public let identifier: String
        public let isCurrent: Bool
        public let packages: [Package]

    }

}

extension OfferingsResponse {

    public struct Package: Sendable {

        public let createdAt: String
        public let displayName: String
        public let id: String
        public let identifier: PackageType
        public let products: [Product]

    }

}

extension OfferingsResponse {

    public struct Product: Sendable {

        public let app: App
        public let createdAt: String
        public let displayName: String?
        public let id: String
        public let identifier: String
        public let isSubscription: Bool

        public struct App: Sendable {

            public let id: String
            public let name: String
            public let type: String

        }

    }

}

extension OfferingsResponse.Product.App: Decodable {}
extension OfferingsResponse.Product: Decodable {}
extension OfferingsResponse.Offering: Decodable {}
extension OfferingsResponse.Package: Decodable {}

extension OfferingsResponse.Product.App: Hashable {}
extension OfferingsResponse.Product: Hashable {}
extension OfferingsResponse.Package: Hashable {}
extension OfferingsResponse.Offering: Hashable {}

extension OfferingsResponse: Equatable { }
extension OfferingsResponse: Hashable { }


extension OfferingsResponse: Decodable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        self.all = try container.decode([Offering].self)
    }

}
