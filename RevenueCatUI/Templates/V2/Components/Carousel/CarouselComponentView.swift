//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CarouselComponentView.swift
//
//  Created by Josh Holtz on 1/27/25.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CarouselComponentView: View {

    let viewModel: CarouselComponentViewModel
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { reader in
            CarouselView(
                pages: [
                    AnyView(Text("First")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)),
                    AnyView(Text("Second")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)),
                    AnyView(Text("Third")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(12)),
                    AnyView(Text("Fourth")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12))
                ],
                loop: true,
                spacing: 16,
                cardWidth: reader.size.width - (40 * 2) - 16
            )
        }
        .frame(height: 240)
        .padding(.top, 50)
    }

}

/// A wrapper to give each page copy a stable, unique identity.
private struct CarouselItem<Content: View>: Identifiable {
    let id: Int         // or UUID()
    let view: Content
}

private struct CarouselView<Content: View>: View {
    // MARK: - Configuration

    private let originalPages: [Content]
    private let loop: Bool
    private let spacing: CGFloat
    private let cardWidth: CGFloat

    /// The number of pages in the user’s original set.
    private var originalCount: Int { originalPages.count }

    // MARK: - State

    /// The “expanded” data array, each with a stable ID.
    @State private var data: [CarouselItem<Content>] = []

    /// The current index (in `data`) of the “active” page.
    @State private var index: Int = 0

    /// Real‐time drag offset from the user’s finger.
    @GestureState private var translation: CGFloat = 0

    // MARK: - Initializer

    init(
        pages: [Content],
        loop: Bool = false,
        spacing: CGFloat = 16,
        cardWidth: CGFloat = 300
    ) {
        self.originalPages = pages
        self.loop = loop
        self.spacing = spacing
        self.cardWidth = cardWidth
    }

    // Because we can’t use property wrappers in initializers directly, we do setup in `onAppear`.
    // Or you could do a custom init that sets up `data` and `index` if you prefer.

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            VStack {
                HStack(spacing: spacing) {
                    ForEach(data) { item in
                        item.view
                            .frame(width: cardWidth)
                    }
                }
                .frame(width: geo.size.width, alignment: .leading)
                .offset(x: xOffset(in: geo.size.width))
                // Animate final snapping only
                .animation(.spring(), value: index)
                .gesture(
                    DragGesture()
                        .updating($translation) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            handleDragEnd(translation: value.translation.width)
                        }
                )

                // Simple pager dots for the original pages
                if originalCount > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<originalCount, id: \.self) { i in
                            Circle()
                                .fill(currentDotIndex() == i ? Color.primary : Color.secondary.opacity(0.4))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .onAppear {
                // Set up our initial data (e.g. 3 copies if loop == true).
                setupData()
            }
        }
        .frame(height: 240)
    }

    // MARK: - Setup

    private func setupData() {
        guard !originalPages.isEmpty else { return }

        if loop {
            // Start with 3 copies so we can swipe freely left or right.
            // We generate stable IDs for each item in each copy.
            let firstCopy = makeItems(forCopyIndex: 0)
            let secondCopy = makeItems(forCopyIndex: 1)
            let thirdCopy = makeItems(forCopyIndex: 2)

            data = firstCopy + secondCopy + thirdCopy

            // Start index in the “middle” copy so user is effectively in center.
            index = originalCount
        } else {
            // Non-looping: just one copy.
            data = makeItems(forCopyIndex: 0)
            index = 0
        }
    }

    /// Creates one “copy” of the original pages, each with a unique ID offset
    /// to distinguish them from other copies.
    private func makeItems(forCopyIndex copyIndex: Int) -> [CarouselItem<Content>] {
        // If you want a simpler ID strategy, you can do copyIndex * originalCount + pageIndex.
        originalPages.enumerated().map { (pageIndex, view) in
            let uniqueID = copyIndex * originalCount + pageIndex
            return CarouselItem(id: uniqueID, view: view)
        }
    }

    // MARK: - Layout

    private func xOffset(in totalWidth: CGFloat) -> CGFloat {
        let itemWidth = cardWidth + spacing
        let baseOffset = -CGFloat(index) * itemWidth
        let dragOffset = translation
        let centerAdjustment = (totalWidth - cardWidth) / 2

        return baseOffset + dragOffset + centerAdjustment
    }

    // MARK: - Gestures

    private func handleDragEnd(translation: CGFloat) {
        let threshold = cardWidth / 2

        if translation < -threshold {
            // Swipe left => next page
            index += 1
        } else if translation > threshold {
            // Swipe right => previous page
            index -= 1
        }

        // If looping, expand + prune around our new index.
        if loop {
            expandDataIfNeeded()
            pruneDataIfNeeded()
        } else {
            // Non-loop: clamp index
            index = max(0, min(index, data.count - 1))
        }
    }

    private func currentDotIndex() -> Int {
        guard originalCount > 0 else { return 0 }
        // The user sees the “logical” page = index mod originalCount
        return index % originalCount
    }

    // MARK: - Expanding

    /// If we’re near the edges, add new copies so we can keep swiping infinitely.
    private func expandDataIfNeeded() {
        // If user is in the first copy, prepend another copy before it
        if index < originalCount {
            // Insert at front. shift index so user sees no jump
            let newCopyIndex = (lowestCopyIndex() - 1)
            let newItems = makeItems(forCopyIndex: newCopyIndex)
            data.insert(contentsOf: newItems, at: 0)
            index += originalCount
        }

        // If user is in the last copy, append another
        if index >= data.count - originalCount {
            let newCopyIndex = (highestCopyIndex() + 1)
            let newItems = makeItems(forCopyIndex: newCopyIndex)
            data.append(contentsOf: newItems)
        }
    }

    // MARK: - Pruning

    /// Remove offscreen copies if we have too many, so memory doesn’t grow forever.
    private func pruneDataIfNeeded() {
        let copiesInData = data.count / originalCount
        let maxCopiesAllowed = 5

        guard copiesInData > maxCopiesAllowed else { return }

        // If the user is at least 2 copies in from the front, remove one from the front
        while index >= 2 * originalCount,
              data.count / originalCount > maxCopiesAllowed
        {
            // Remove 1 copy from the front
            data.removeFirst(originalCount)
            // Adjust index
            index -= originalCount
        }

        // If the user is at least 2 copies away from the end
        // (index < data.count - 2 * originalCount), remove one from the end
        while index < data.count - 2 * originalCount,
              data.count / originalCount > maxCopiesAllowed
        {
            // Remove 1 copy from the end
            data.removeLast(originalCount)
            // No need to adjust index because we removed from the back
        }
    }

    // Helpers to figure out which “copy indices” we have in data
    private func lowestCopyIndex() -> Int {
        guard let firstID = data.first?.id else { return 0 }
        // Since we used `id = copyIndex * originalCount + pageIndex`,
        // integer division by originalCount recovers the copyIndex.
        return firstID / originalCount
    }

    private func highestCopyIndex() -> Int {
        guard let lastID = data.last?.id else { return 0 }
        return lastID / originalCount
    }
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CarouselComponentView_Previews: PreviewProvider {

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {
        // Default
        VStack {
            CarouselComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(slides: []),
                    slideStackViewModel: []
                ),
                onDismiss: {}
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Default")
    }

}

#endif

#endif
