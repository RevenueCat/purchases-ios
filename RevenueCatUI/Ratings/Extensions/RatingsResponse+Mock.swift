//
//  RatingsResponse+Mock.swift
//
//  Created by RevenueCat on 1/2/25.
//

import Foundation
@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension RatingsResponse.Review {
    static func mock() -> RatingsResponse.Review {
        return RatingsResponse.Review(
            id: "mock_review_\(UUID().uuidString)",
            title: "Great App!",
            body: "This app works perfectly and has an amazing user interface. Highly recommended!",
            rating: 5,
            reviewerNickname: "HappyUser",
            territory: "US",
            createdDate: "2023-01-15T10:30:00.000Z"
        )
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
