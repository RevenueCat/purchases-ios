//
//  MemojisStack.swift
//
//  Created by James Sedlacek on 3/7/25.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct MemojisStack: View {
    let memojis: [Image]
    var body: some View {
        HStack(alignment: .center, spacing: -10) {
            memoji(at: 1)
                .zIndex(3)

            memoji(at: 2)
                .zIndex(2)

            memoji(at: 3)
                .zIndex(1)
        }
    }

    @ViewBuilder
    private func memoji(at index: Int) -> some View {
        if let memoji = memojis[safe: index] {
            memoji
                .resizable()
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .clipShape(.circle)
                .background(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 4)
                )
        }
    }
}

#if DEBUG
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct MemojisStack_Previews: PreviewProvider {
    static var previews: some View {
        MemojisStack(memojis: RatingRequestConfiguration.defaultMemojis)
            .padding()
    }
}
#endif
