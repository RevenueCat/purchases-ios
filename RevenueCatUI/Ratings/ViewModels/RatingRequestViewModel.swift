//
//  RatingRequestViewModel.swift
//
//  Created by RevenueCat on 1/2/25.
//

import Foundation
@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
class RatingRequestViewModel: ObservableObject {

    @Published var state: RatingRequestState = .loading
    @Published var ratingsData: RatingsResponse?

    init() {}

    func fetchRatings() async {
        state = .loading

        // Add a realistic delay to see loading state
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Mock different responses for testing
        await simulateResponse()
    }

    private func simulateResponse() async {
        let responses: [() -> Void] = [
            // Success with full data
            {
                self.ratingsData = RatingsResponse(
                    averageUserRating: 4.5,
                    userRatingCount: 1247,
                    reviews: [
                        RatingsResponse.Review(
                            id: "review_1",
                            title: "Amazing app!",
                            body: "This app has completely changed how I manage my subscriptions. The interface is intuitive and the features are exactly what I needed. Highly recommend!",
                            rating: 5,
                            reviewerNickname: "TechLover42",
                            territory: "US",
                            createdDate: "2024-01-15T10:30:00.000Z"
                        ),
                        RatingsResponse.Review(
                            id: "review_2",
                            title: "Great features",
                            body: "Love the clean design and ease of use. Only minor complaint is that some features could be more discoverable.",
                            rating: 4,
                            reviewerNickname: "DesignFan",
                            territory: "CA",
                            createdDate: "2024-01-10T14:22:00.000Z"
                        ),
                        RatingsResponse.Review(
                            id: "review_3",
                            title: "Perfect for my needs",
                            body: "Simple and effective. Does exactly what it promises.",
                            rating: 5,
                            reviewerNickname: "BusyParent",
                            territory: "UK",
                            createdDate: "2024-01-08T09:15:00.000Z"
                        ),
                        RatingsResponse.Review(
                            id: "review_4",
                            title: "Good but could be better",
                            body: "The app works well overall, but I'd love to see more customization options in future updates.",
                            rating: 3,
                            reviewerNickname: "PowerUser99",
                            territory: "DE",
                            createdDate: "2024-01-05T16:45:00.000Z"
                        )
                    ]
                )
                self.state = .loaded
            },

            // Success with ratings but no written reviews
            {
                self.ratingsData = RatingsResponse(
                    averageUserRating: 4.2,
                    userRatingCount: 89,
                    reviews: []
                )
                self.state = .loaded
            },

            // Success with no ratings at all
            {
                self.ratingsData = RatingsResponse(
                    averageUserRating: 0.0,
                    userRatingCount: 0,
                    reviews: []
                )
                self.state = .loaded
            },

            // Error state
            {
                self.state = .error("Failed to load ratings. Please check your internet connection and try again.")
            },

            // Network timeout error
            {
                self.state = .error("Request timed out. The server might be experiencing high traffic.")
            }
        ]

        // Randomly select a response for testing
//        let randomResponse = responses.randomElement()!
//        randomResponse()
        responses[0]()

        // Uncomment to test specific states:
        // responses[0]() // Full data
        // responses[1]() // Ratings but no reviews  
        // responses[2]() // No data
        // responses[3]() // Error
    }
}
