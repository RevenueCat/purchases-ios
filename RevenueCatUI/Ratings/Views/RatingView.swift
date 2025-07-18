//
//  RatingView.swift
//
//  Created by RevenueCat on 1/2/25.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct RatingView: View {

    let rating: Double
    let maxRating: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxRating, id: \.self) { index in
                Image(systemName: starIcon(for: index))
                    .foregroundColor(.yellow)
                    .font(.title2)
            }
        }
    }

    private func starIcon(for index: Int) -> String {
        let threshold = Double(index + 1)

        if rating >= threshold {
            return "star.fill"
        } else if rating >= threshold - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}
