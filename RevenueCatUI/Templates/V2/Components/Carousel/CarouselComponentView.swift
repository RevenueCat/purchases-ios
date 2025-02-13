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

// TODO: add default selected index
// TODO: add colors and size to indicator
// TODO: fix touching on animated
// TODO: SUPER FUTURE - drag on indicator

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CarouselComponentView: View {

    let viewModel: CarouselComponentViewModel
    let onDismiss: () -> Void

    var body: some View {
        EmptyView()
        GeometryReader { reader in
            CarouselView(
                pages: self.viewModel.pageStackViewModels.map({ stackViewModel in
                    StackComponentView(
                        viewModel: stackViewModel,
                        onDismiss: self.onDismiss
                    )
                }),
                initialIndex: self.viewModel.component.initialPageIndex,
                loop: self.viewModel.component.loop,
                spacing: CGFloat(self.viewModel.component.pageSpacing),
                cardWidth: reader.size.width - CGFloat(self.viewModel.component.pagePeek * 2) - CGFloat(self.viewModel.component.pageSpacing),
                pageControl: self.viewModel.displayablePageControl,
                msTimePerSlide: viewModel.component.autoAdvance?.msTimePerPage,
                msTransitionTime: viewModel.component.autoAdvance?.msTransitionTime
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct CarouselView<Content: View>: View {
    // MARK: - Configuration

    private let initialIndex: Int
    private let originalPages: [Content]
    private let loop: Bool
    private let spacing: CGFloat
    private let cardWidth: CGFloat

    private let pageControl: DisplayablePageControl

    /// Optional auto-play timings (in milliseconds).
    private let msTimePerSlide: Int?
    private let msTransitionTime: Int?

    // Number of pages in the user's original set.
    private var originalCount: Int { originalPages.count }

    // MARK: - State

    /// The “expanded” data array, each item with a unique ID.
    @State private var data: [CarouselItem<Content>] = []

    /// The current index (in `data`) of the "active" page.
    @State private var index: Int = 0

    /// Real-time drag offset from the user’s finger.
    @GestureState private var translation: CGFloat = 0

    /// A timer for auto-play, if enabled.
    @State private var autoTimer: Timer? = nil

    // MARK: - Init

    init(
        pages: [Content],
        initialIndex: Int,
        loop: Bool = false,
        spacing: CGFloat = 16,
        cardWidth: CGFloat = 300,
        pageControl: DisplayablePageControl,
        /// If either of these is nil, auto‐play is off.
        msTimePerSlide: Int? = nil,
        msTransitionTime: Int? = nil
    ) {
        self.initialIndex = initialIndex
        self.originalPages = pages
        self.loop = loop
        self.spacing = spacing
        self.cardWidth = cardWidth
        self.pageControl = pageControl
        self.msTimePerSlide = msTimePerSlide
        self.msTransitionTime = msTransitionTime
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            VStack {
                // Main horizontal “strip” of pages:
                HStack(spacing: spacing) {
                    ForEach(data) { item in
                        item.view
                            .frame(width: cardWidth)
                    }
                }
                .frame(width: geo.size.width, alignment: .leading)
                .offset(x: xOffset(in: geo.size.width))
                // Animate only final snaps (or auto transitions), not real-time dragging
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

                // Pager dots for the original set
                if originalCount > 1 {
                    PageControlView(
                        originalCount: self.originalCount,
                        pageControl: self.pageControl,
                        currentIndex: self.$index
                    )
                    .padding(.top, 8)
                }
            }
            .onAppear {
                setupData()
                startAutoPlayIfNeeded()
            }
            .onDisappear {
                // Stop the timer if view disappears
                autoTimer?.invalidate()
                autoTimer = nil
            }
        }
        .frame(height: 240) // Adjust as desired
    }

    // MARK: - Setup

    private func setupData() {
        guard !originalPages.isEmpty else { return }

        if loop {
            // Start with 3 copies so user can swipe freely left or right.
            let firstCopy  = makeItems(forCopyIndex: 0)
            let secondCopy = makeItems(forCopyIndex: 1)
            let thirdCopy  = makeItems(forCopyIndex: 2)

            data = firstCopy + secondCopy + thirdCopy

            // Put user in the middle copy
            index = originalCount + self.initialIndex
        } else {
            // Non-looping: just one copy
            data = makeItems(forCopyIndex: 0)
            index = self.initialIndex
        }
    }

    /// Create one “copy” of the original pages, each with a unique ID
    /// so SwiftUI knows these are distinct items from other copies.
    private func makeItems(forCopyIndex copyIndex: Int) -> [CarouselItem<Content>] {
        originalPages.enumerated().map { (pageIndex, view) in
            let uniqueID = copyIndex * originalCount + pageIndex
            return CarouselItem(id: uniqueID, view: view)
        }
    }

    // MARK: - Auto-Play

    private func startAutoPlayIfNeeded() {
        guard let msTimePerSlide = msTimePerSlide,
              let msTransitionTime = msTransitionTime else { return }

        // We schedule a repeating timer that advances to the next page every `msTimePerSlide`.
        autoTimer = Timer.scheduledTimer(withTimeInterval: Double(msTimePerSlide) / 1000, repeats: true) { _ in
            // We animate the transition over `msTransitionTime` milliseconds
            withAnimation(.easeInOut(duration: Double(msTransitionTime) / 1000)) {
                index += 1
                if loop {
                    expandDataIfNeeded()
                    pruneDataIfNeeded()
                } else {
                    // If non-loop, just clamp
                    index = min(index, data.count - 1)
                }
            }
        }
    }

    // MARK: - Offsets

    private func xOffset(in totalWidth: CGFloat) -> CGFloat {
        let itemWidth = cardWidth + spacing
        let baseOffset = -CGFloat(index) * itemWidth
        let centerAdjustment = (totalWidth - cardWidth) / 2
        return baseOffset + translation + centerAdjustment
    }

    // MARK: - Drag Handling

    private func handleDragEnd(translation: CGFloat) {
        let threshold = cardWidth / 2

        if translation < -threshold {
            // Swipe left => next
            index += 1
        } else if translation > threshold {
            // Swipe right => prev
            index -= 1
        }

        if loop {
            expandDataIfNeeded()
            pruneDataIfNeeded()
        } else {
            // Non-loop clamp
            index = max(0, min(index, data.count - 1))
        }
    }

    // MARK: - Expanding

    private func expandDataIfNeeded() {
        // If index is in the first copy, prepend another
        if index < originalCount {
            let newCopyIndex = lowestCopyIndex() - 1
            let newItems = makeItems(forCopyIndex: newCopyIndex)
            data.insert(contentsOf: newItems, at: 0)
            index += originalCount // keep user in same “visual” position
        }

        // If index is in the last copy, append another
        if index >= data.count - originalCount {
            let newCopyIndex = highestCopyIndex() + 1
            let newItems = makeItems(forCopyIndex: newCopyIndex)
            data.append(contentsOf: newItems)
        }
    }

    // MARK: - Pruning

    private func pruneDataIfNeeded() {
        let copiesInData = data.count / originalCount
        let maxCopiesAllowed = 5

        guard copiesInData > maxCopiesAllowed else { return }

        // If user is at least 2 copies in from the front, we can drop 1 copy from the front.
        while index >= 2 * originalCount,
              data.count / originalCount > maxCopiesAllowed
        {
            data.removeFirst(originalCount)
            index -= originalCount
        }

        // If user is at least 2 copies from the end, we can drop 1 copy from the end.
        while index < data.count - 2 * originalCount,
              data.count / originalCount > maxCopiesAllowed
        {
            data.removeLast(originalCount)
        }
    }

    // Identify which copy indices we have
    private func lowestCopyIndex() -> Int {
        guard let firstID = data.first?.id else { return 0 }
        return firstID / originalCount
    }

    private func highestCopyIndex() -> Int {
        guard let lastID = data.last?.id else { return 0 }
        return lastID / originalCount
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PageControlView: View {

    let originalCount: Int
    let pageControl: DisplayablePageControl
    @Binding var currentIndex: Int

    @State private var localCurrentIndex: Int = 0

    var activeIndicator: DisplayablePageControlIndicator {
        pageControl.active
    }

    var indicator: DisplayablePageControlIndicator {
        pageControl.default
    }

    var body: some View {
        HStack(spacing: self.pageControl.spacing) {
            ForEach(0..<originalCount, id: \.self) { index in
                Capsule()
                    .fill(localCurrentIndex == index ? activeIndicator.color : indicator.color)
                    .frame(
                        width: localCurrentIndex == index ? activeIndicator.width : indicator.width,
                        height: localCurrentIndex == index ? activeIndicator.height : indicator.height
                    )
                    .animation(.easeInOut, value: self.localCurrentIndex)
            }
        }
        .padding(self.pageControl.padding)
        .shape(border: pageControl.border,
               shape: pageControl.shape,
               background: pageControl.backgroundStyle,
               uiConfigProvider: pageControl.uiConfigProvider)
        .shadow(shadow: pageControl.shadow, shape: pageControl.shape?.toInsettableShape())
        .padding(self.pageControl.margin)
        .onChange(of: self.currentIndex) { newValue in
            withAnimation {
                guard originalCount > 0 else {
                    self.localCurrentIndex = 0
                    return
                }
                self.localCurrentIndex = newValue % originalCount
            }
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CarouselComponentView_Previews: PreviewProvider {

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {
        // Examples
        VStack {
            CarouselComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    component: .init(
                        pages: [
                            .init(
                                components: [],
                                size: .init(width: .fill, height: .fixed(120)),
                                backgroundColor: .init(light: .hex("#FF0000")),
                                shape: .rectangle(.init(topLeading: 8,
                                                        topTrailing: 8,
                                                        bottomLeading: 8,
                                                        bottomTrailing: 8))
                            ),
                            .init(
                                components: [],
                                size: .init(width: .fill, height: .fixed(120)),
                                backgroundColor: .init(light: .hex("#00FF00")),
                                shape: .rectangle(.init(topLeading: 8,
                                                        topTrailing: 8,
                                                        bottomLeading: 8,
                                                        bottomTrailing: 8))
                            ),
                            .init(
                                components: [],
                                size: .init(width: .fill, height: .fixed(120)),
                                backgroundColor: .init(light: .hex("#0000FF")),
                                shape: .rectangle(.init(topLeading: 8,
                                                        topTrailing: 8,
                                                        bottomLeading: 8,
                                                        bottomTrailing: 8))
                            )
                        ],
                        pageSpacing: 20,
                        pagePeek: 40,
                        initialPageIndex: 1,
                        loop: false,
                        pageControl: .init(
                            position: .bottom,
                            padding: .init(top: 6, bottom: 6, leading: 20, trailing: 20),
                            margin: .init(top: 20, bottom: 20, leading: 0, trailing: 0),
                            backgroundColor: .init(light: .hex("#f0f0f0")),
                            shape: .pill,
                            border: nil,
                            shadow: .init(color: .init(light: .hex("#00000066")), radius: 4, x: 2, y: 2),
                            spacing: 10,
                            default: .init(
                                width: 10,
                                height: 10,
                                color: .init(light: .hex("#aeaeae"))
                            ),
                            active: .init(
                                width: 10,
                                height: 10,
                                color: .init(light: .hex("#000000"))
                            )
                        )
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    )
                ),
                onDismiss: {}
            )

            CarouselComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    component: .init(
                        pages: [
                            .init(
                                components: [],
                                size: .init(width: .fixed(100), height: .fixed(120)),
                                backgroundColor: .init(light: .hex("#FF0000")),
                                shape: .rectangle(.init(topLeading: 8,
                                                        topTrailing: 8,
                                                        bottomLeading: 8,
                                                        bottomTrailing: 8))
                            ),
                            .init(
                                components: [],
                                size: .init(width: .fixed(100), height: .fixed(120)),
                                backgroundColor: .init(light: .hex("#00FF00")),
                                shape: .rectangle(.init(topLeading: 8,
                                                        topTrailing: 8,
                                                        bottomLeading: 8,
                                                        bottomTrailing: 8))
                            ),
                            .init(
                                components: [],
                                size: .init(width: .fixed(100), height: .fixed(120)),
                                backgroundColor: .init(light: .hex("#0000FF")),
                                shape: .rectangle(.init(topLeading: 8,
                                                        topTrailing: 8,
                                                        bottomLeading: 8,
                                                        bottomTrailing: 8))
                            )
                        ],
                        loop: true,
                        pageControl: .init(
                            position: .bottom,
                            padding: .init(top: 10, bottom: 10, leading: 16, trailing: 16),
                            margin: .init(top: 10, bottom: 10, leading: 0, trailing: 0),
                            backgroundColor: nil,
                            shape: .rectangle(.init(topLeading: 8, topTrailing: 8, bottomLeading: 8, bottomTrailing: 8)),
                            border: .init(color: .init(light: .hex("#cccccc")), width: 1),
                            shadow: nil,
                            spacing: 10,
                            default: .init(
                                width: 10,
                                height: 10,
                                color: .init(light: .hex("#cccccc"))
                            ),
                            active: .init(
                                width: 10,
                                height: 10,
                                color: .init(light: .hex("#000000"))
                            )
                        )
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    )
                ),
                onDismiss: {}
            )
            .clipped()

            CarouselComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    component: .init(
                        pages: [
                            .init(
                                components: [],
                                size: .init(width: .fill, height: .fixed(120)),
                                backgroundColor: .init(light: .hex("#FF0000")),
                                shape: .rectangle(.init(topLeading: 8,
                                                        topTrailing: 8,
                                                        bottomLeading: 8,
                                                        bottomTrailing: 8))
                            ),
                            .init(
                                components: [],
                                size: .init(width: .fill, height: .fixed(120)),
                                backgroundColor: .init(light: .hex("#00FF00")),
                                shape: .rectangle(.init(topLeading: 8,
                                                        topTrailing: 8,
                                                        bottomLeading: 8,
                                                        bottomTrailing: 8))
                            ),
                            .init(
                                components: [],
                                size: .init(width: .fill, height: .fixed(120)),
                                backgroundColor: .init(light: .hex("#0000FF")),
                                shape: .rectangle(.init(topLeading: 8,
                                                        topTrailing: 8,
                                                        bottomLeading: 8,
                                                        bottomTrailing: 8))
                            )
                        ],
                        pageSpacing: 20,
                        pagePeek: 20,
                        initialPageIndex: 1,
                        loop: true,
                        autoAdvance: .init(msTimePerPage: 1000, msTransitionTime: 500),
                        pageControl: .init(
                            position: .bottom,
                            padding: .init(top: 0, bottom: 0, leading: 0, trailing: 0),
                            margin: .init(top: 10, bottom: 10, leading: 0, trailing: 0),
                            backgroundColor: nil,
                            shape: nil,
                            border: nil,
                            shadow: nil,
                            spacing: 10,
                            default: .init(
                                width: 10,
                                height: 10,
                                color: .init(light: .hex("#4462e96e"))
                            ),
                            active: .init(
                                width: 60,
                                height: 20,
                                color: .init(light: .hex("#4462e9"))
                            )
                        )
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    )
                ),
                onDismiss: {}
            )
        }
        .padding(.vertical)
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Examples")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CarouselComponentViewModel {

    convenience init(
        component: PaywallComponent.CarouselComponent,
        localizationProvider: LocalizationProvider
    ) throws {
        let viewModels: [StackComponentViewModel] = try component.pages.map { component in
            return try .init(
                component: component,
                localizationProvider: localizationProvider
            )
        }

        try self.init(
            localizationProvider: localizationProvider,
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            component: component,
            pageStackViewModels: viewModels
        )
    }

}

#endif

#endif
