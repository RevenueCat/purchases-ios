//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RatingsResponse.swift
//
//  Created by RevenueCat on 1/2/25.
//

import Foundation

public struct RatingsResponse {

    public let averageUserRating: Double
    public let userRatingCount: Int
    public let reviews: [Review]

    public init(averageUserRating: Double, userRatingCount: Int, reviews: [Review]) {
        self.averageUserRating = averageUserRating
        self.userRatingCount = userRatingCount
        self.reviews = reviews
    }

    public struct Review {
        public let id: String
        public let title: String
        public let body: String
        public let rating: Int
        public let reviewerNickname: String
        public let territory: String
        public let createdDate: String

        public init(id: String, title: String, body: String, rating: Int, reviewerNickname: String, territory: String, createdDate: String) {
            self.id = id
            self.title = title
            self.body = body
            self.rating = rating
            self.reviewerNickname = reviewerNickname
            self.territory = territory
            self.createdDate = createdDate
        }
    }

}

// MARK: - Codable

extension RatingsResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case averageUserRating = "average_user_rating"
        case userRatingCount = "user_rating_count"
        case reviews
    }

}

extension RatingsResponse.Review: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case rating
        case reviewerNickname = "reviewer_nickname"
        case territory
        case createdDate = "created_date"
    }

}

// MARK: - HTTPResponseBody

extension RatingsResponse: HTTPResponseBody {}
