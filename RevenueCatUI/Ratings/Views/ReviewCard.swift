//
//  ReviewCard.swift
//
//  Created by RevenueCat on 1/2/25.
//

@_spi(Internal) import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ReviewCard: View {

    let review: RatingsResponse.Review
    let memoji: Image

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            contentSection
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var headerSection: some View {
        HStack {
            memoji
                .font(.title)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(review.reviewerNickname)
                    .font(.headline)
                    .foregroundColor(.primary)

                RatingView(rating: Double(review.rating))
            }

            Spacer()

            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !review.title.isEmpty {
                Text(review.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            }

            if !review.body.isEmpty {
                Text(review.body)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var formattedDate: String {
        // Simple date formatting - in a real app you'd want proper date parsing
        let dateString = review.createdDate
        if let date = ISO8601DateFormatter().date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return dateString
    }
}
