//
//  RatingRequestScreen.swift
//
//  Created by RevenueCat on 1/2/25.
//

@_spi(Internal) import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct RatingRequestScreen {

    @StateObject private var viewModel: RatingRequestViewModel
    let configuration: RatingRequestConfiguration

    public init(configuration: RatingRequestConfiguration = .default) {
        self.configuration = configuration
        self._viewModel = StateObject(wrappedValue: RatingRequestViewModel())
    }

    // MARK: - Computed Properties

    var state: RatingRequestState {
        viewModel.state
    }

    var averageRating: Double {
        viewModel.ratingsData?.averageUserRating ?? 0.0
    }

    var totalRatings: Int {
        viewModel.ratingsData?.userRatingCount ?? 0
    }

    var reviews: [RatingsResponse.Review] {
        viewModel.ratingsData?.reviews ?? []
    }

    var isShowingNoRatings: Bool {
        !state.isLoading && totalRatings == 0
    }

    var isShowingNoReviews: Bool {
        !state.isLoading && reviews.isEmpty && totalRatings > 0
    }

    // MARK: - Actions

    func fetchData() async {
        await viewModel.fetchRatings()
    }

    func ratingRequestAction() {
        configuration.primaryButtonAction?()
    }

    var secondaryButtonAction: (() -> Void)? {
        configuration.secondaryButtonAction
    }

    func tryAgainAction() {
        Task {
            await viewModel.fetchRatings()
        }
    }
}
