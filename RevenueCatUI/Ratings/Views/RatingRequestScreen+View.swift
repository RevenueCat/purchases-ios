//
//  RatingRequestScreen+View.swift
//
//  Created by RevenueCat on 1/2/25.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension RatingRequestScreen: View {
    public var body: some View {
        VStack(spacing: 16) {
            headerSection
            reviewList
                .safeAreaInset(
                    edge: .bottom,
                    content: callToActionSection
                )
        }
        .padding(.vertical)
        .background(.background)
        .overlay(content: errorStateView)
        .task {
            await fetchData()
        }
    }
}

// MARK: Header Section
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension RatingRequestScreen {
    private var headerSection: some View {
        VStack(alignment: .center, spacing: 12) {
            titleView
            averageRatingView
            totalRatingsView
        }
    }

    private var titleView: some View {
        Text(configuration.screenTitle)
            .font(.largeTitle.bold())
    }

    private var averageRatingView: some View {
        Group {
            if state.isLoading {
                RatingView(rating: averageRating)
                    .redacted(reason: .placeholder)
            } else {
                RatingView(rating: averageRating)
            }
        }
    }

    @ViewBuilder
    private var totalRatingsView: some View {
        if isShowingNoRatings {
            Text("No ratings yet")
        } else {
            HStack {
                MemojisStack(memojis: configuration.memojis)
                Group {
                    if state.isLoading {
                        Text("\(totalRatings) ratings")
                            .font(.body.weight(.medium))
                            .redacted(reason: .placeholder)
                    } else {
                        Text("\(totalRatings) ratings")
                            .font(.body.weight(.medium))
                    }
                }
            }
        }
    }
}

// MARK: Review List
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension RatingRequestScreen {
    private var reviewList: some View {
        List {
            if state.isLoading {
                loadingReviewCards
            } else {
                reviewCards
            }
        }
        .listSectionSeparator(.hidden)
        .listStyle(.plain)
        .overlay(noReviewsView)
    }

    private var loadingReviewCards: some View {
        ForEach(0..<5, id: \.self) { _ in
            ReviewCard(review: .mock(), memoji: Image(systemName: "person.circle"))
                .redacted(reason: .placeholder)
                .listRowSeparator(.hidden)
        }
    }

    private var reviewCards: some View {
        ForEach(reviews.indices, id: \.self) { index in
            if let review = reviews[safe: index],
               let memoji = configuration.memojis[safe: index] {
                ReviewCard(review: review, memoji: memoji)
                    .listRowSeparator(.hidden)
            }
        }
    }

    @ViewBuilder
    private var noReviewsView: some View {
        if isShowingNoReviews {
            NoReviewsView()
        }
    }
}

// MARK: Call to Action Section
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension RatingRequestScreen {
    @ViewBuilder
    private func callToActionSection() -> some View {
        if !state.isLoading {
            VStack(spacing: .zero) {
                primaryButton
                secondaryButton
            }
            .background(.background)
            .transition(.move(edge: .bottom))
        }
    }

    private var primaryButton: some View {
        Button(
            action: ratingRequestAction,
            label: {
                Text(configuration.primaryButtonTitle)
                    .frame(maxWidth: .infinity)
                    .font(.headline.weight(.semibold))
                    .frame(height: 42)
            }
        )
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle)
        .padding()
    }

    @ViewBuilder
    private var secondaryButton: some View {
        if let secondaryButtonAction {
            Button(
                action: secondaryButtonAction,
                label: {
                    Text(configuration.secondaryButtonTitle)
                        .font(.subheadline.weight(.medium))
                }
            )
            .buttonStyle(.borderless)
        }
    }
}

// MARK: Error State
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension RatingRequestScreen {
    @ViewBuilder
    private func errorStateView() -> some View {
        if let errorMessage = state.errorMessage {
            TryAgainView(
                errorMessage: errorMessage,
                tryAgainAction: tryAgainAction
            )
        }
    }
}
