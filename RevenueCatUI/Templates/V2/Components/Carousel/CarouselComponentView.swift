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
// swiftlint:disable file_length

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CarouselComponentView: View {

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @Environment(\.colorScheme)
    private var colorScheme

    let viewModel: CarouselComponentViewModel
    let onDismiss: () -> Void

    @State private var carouselHeight: CGFloat = 0

    var body: some View {
        viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            ),
            isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(
                for: self.packageContext.package
            ),
            colorScheme: colorScheme
        ) { style in
            if style.visible {
                GeometryReader { reader in
                    CarouselView(
                        width: reader.size.width,
                        pageAlignment: style.pageAlignment,
                        pages: self.viewModel.pageStackViewModels.map({ stackViewModel in
                            StackComponentView(
                                viewModel: stackViewModel,
                                onDismiss: self.onDismiss
                            )
                        }),
                        initialIndex: style.initialPageIndex,
                        loop: style.loop,
                        spacing: style.pageSpacing,
                        cardWidth: reader.size.width - (style.pagePeek * 2) - (style.pageSpacing * 2),
                        pageControl: style.pageControl,
                        msTimePerSlide: style.autoAdvance?.msTimePerPage,
                        msTransitionTime: style.autoAdvance?.msTransitionTime,
                        autoAdvanceTransitionType: style.autoAdvance?.transitionType
                    ).clipped()
                }
                // Need to set height since geometry reader has no intrinsic height
                .frame(height: carouselHeight)
                .onPreferenceChange(HeightPreferenceKey.self) { newHeight in
                    self.carouselHeight = newHeight
                }
                // Style the carousel
                .size(style.size)
                .padding(style.padding.extend(by: style.border?.width ?? 0))
                .shape(border: style.border,
                       shape: style.shape,
                       background: style.backgroundStyle,
                       uiConfigProvider: self.viewModel.uiConfigProvider)
                .shadow(shadow: style.shadow, shape: style.shape?.toInsettableShape())
                .padding(style.margin)
            }
        }
    }

}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// A wrapper to give each page copy a stable, unique identity.
private struct CarouselItem<Content: View>: Identifiable {
    let id: Int
    let view: Content
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct CarouselView<Content: View>: View {
    // MARK: - Configuration

    private let pageAlignment: VerticalAlignment
    private let width: CGFloat
    private let initialIndex: Int
    private let originalPages: [Content]
    private let loop: Bool
    private let spacing: CGFloat
    private let cardWidth: CGFloat

    private let pageControl: DisplayablePageControl?

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
    @State private var autoTimer: Timer?

    @State private var isPaused: Bool = false
    @State private var pauseEndDate: Date?
    @State private var isInitialized = false

    /// Used to keep the drag position for better animations
    @State private var dragOffset: CGFloat = 0

    /// Used to animate opacity for the loop transition
    @State private var opacity: CGFloat = 1.0

    // MARK: - Init

    init(
        width: CGFloat,
        pageAlignment: VerticalAlignment,
        pages: [Content],
        initialIndex: Int,
        loop: Bool,
        spacing: CGFloat,
        cardWidth: CGFloat,
        pageControl: DisplayablePageControl?,
        /// If either of these is nil, auto‐play is off.
        msTimePerSlide: Int?,
        msTransitionTime: Int?,
        autoAdvanceTransitionType: PaywallComponent.CarouselComponent.AutoAdvanceTransitionType?
    ) {
        self.width = width
        self.pageAlignment = pageAlignment
        self.initialIndex = initialIndex
        self.originalPages = pages
        self.loop = loop
        self.spacing = spacing
        self.cardWidth = cardWidth
        self.pageControl = pageControl
        self.msTimePerSlide = msTimePerSlide
        self.msTransitionTime = msTransitionTime
        self.autoAdvanceTransitionType = autoAdvanceTransitionType
            ?? PaywallComponent.CarouselComponent.AutoAdvanceTransitionType.default
    }

    // MARK: - Body

    var transitionTime: Double {
        guard let msTransitionTime = self.msTransitionTime else {
            return 0.25
        }

        if !isInitialized {
            // Prevents any animation when carousel is first coming into view
            return 0
        } else if isPaused {
            return 0.25
        } else {
            return Double(msTransitionTime) / 1000
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // If top page control
            if let pageControl = self.pageControl, pageControl.position == .top {
                PageControlView(
                    originalCount: self.originalCount,
                    pageControl: pageControl,
                    currentIndex: self.$index,
                    animationDuration: fadeDuration.map { $0 / 2 }
                )
            }

            // Main horizontal “strip” of pages:
            HStack(alignment: self.pageAlignment, spacing: spacing) {
                ForEach(data) { item in
                    item.view
                        .frame(width: cardWidth)
                }
            }
            .frame(width: self.width, alignment: .leading)
            .offset(x: xOffset(in: self.width) + dragOffset) // Apply drag offset
            .opacity(opacity)
            .applyIf(autoAdvanceTransitionType == .slide, apply: { view in
                // Animate only final snaps (or auto transitions), not real-time dragging
                view.animation(.easeInOut(duration: self.transitionTime), value: index)
            })
            .gesture(
                DragGesture()

                    .onChanged({ _ in
                        pauseAutoPlay(for: 10)
                    })
                    .updating($translation) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        // Store drag offset to apply nice snap animation when done
                        self.dragOffset = value.translation.width
                        handleDragEnd(translation: value.translation.width)
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        pauseAutoPlay(for: 10) // Pause on any tap interaction
                    }
            )

            // If bottom page control
            if let pageControl = self.pageControl, pageControl.position == .bottom {
                PageControlView(
                    originalCount: self.originalCount,
                    pageControl: pageControl,
                    currentIndex: self.$index,
                    animationDuration: fadeDuration.map { $0 / 2 }
                )
            }
        }
        .background(GeometryReader { geo in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geo.size.height)
        })
        .onAppear {
            setupData()
            startAutoPlayIfNeeded()

            DispatchQueue.main.async {
                self.isInitialized = true
            }
        }
        .onDisappear {
            // Stop the timer if view disappears
            autoTimer?.invalidate()
            autoTimer = nil
        }
    }

    // MARK: - Setup

    /// When `loop` is `true`, and `fadeTransition` is turned on we don't setUp the animation view modifier
    private let autoAdvanceTransitionType: PaywallComponent.CarouselComponent.AutoAdvanceTransitionType

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

    private var autoPlayTimerDuration: TimeInterval? {
        guard let msTimePerSlide = msTimePerSlide,
              let msTransitionTime = msTransitionTime else { return nil }

        return Double(msTimePerSlide + msTransitionTime) / 1000
    }

    // arbitrary but works smoothly
    private var fadeDuration: TimeInterval? {
        guard let msTransitionTime else {
            return nil
        }
        return TimeInterval(msTransitionTime) / 1000
    }

    private func startAutoPlayIfNeeded() {
        guard
            let autoPlayTimerDuration,
            let msTransitionTime,
            let fadeDuration
        else { return }

        autoTimer?.invalidate()

        autoTimer = Timer.scheduledTimer(
            withTimeInterval: autoPlayTimerDuration,
            repeats: true
        ) { _ in
            guard !isPaused else {
                // If paused, check if 10 seconds have passed
                if let pauseEndDate = pauseEndDate, Date() >= pauseEndDate {
                    isPaused = false // Resume auto-play
                }
                return
            }

            switch autoAdvanceTransitionType {
            case .fade:
                // Fade out both slide + indicator
                withAnimation(.easeInOut(duration: fadeDuration)) {
                    opacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
                    index = (index + 1) % data.count
                    if loop {
                        expandDataIfNeeded()
                        pruneDataIfNeeded()
                    }

                    // Fade in both slide + indicator
                    withAnimation(.easeInOut(duration: fadeDuration)) {
                        opacity = 1
                    }
                }
            case .slide:
                withAnimation(.easeInOut(duration: Double(msTransitionTime) / 1000)) {
                    index += 1
                    if loop {
                        expandDataIfNeeded()
                        pruneDataIfNeeded()
                    } else {
                        index = min(index, data.count - 1)
                    }
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
        let threshold = cardWidth * 0.2

        withAnimation(.easeInOut(duration: 0.25)) {
            self.dragOffset = 0

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

        // Pause auto-play for 10 seconds
        pauseAutoPlay(for: 10)
    }

    private var autoPlayEnabled: Bool {
        return self.msTimePerSlide != nil && self.msTransitionTime != nil
    }

    private func pauseAutoPlay(for seconds: TimeInterval) {
        guard self.autoPlayEnabled else { return }

        isPaused = true
        pauseEndDate = Date().addingTimeInterval(seconds)

        // Restart auto-play after `seconds` seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            if Date() >= self.pauseEndDate! {
                self.isPaused = false
            }
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
              data.count / originalCount > maxCopiesAllowed {
            data.removeFirst(originalCount)
            index -= originalCount
        }

        // If user is at least 2 copies from the end, we can drop 1 copy from the end.
        while index < data.count - 2 * originalCount,
              data.count / originalCount > maxCopiesAllowed {
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

    /// Used for fade transition
    /// - Note: This needs to be half of whatever the fade duration is
    let animationDuration: CGFloat?

    @State private var localCurrentIndex: Int = 0

    var activeIndicator: DisplayablePageControlIndicator {
        pageControl.active
    }

    var indicator: DisplayablePageControlIndicator {
        pageControl.default
    }

    var body: some View {
        if self.originalCount > 1 {
            HStack(spacing: self.pageControl.spacing) {
                ForEach(0..<originalCount, id: \.self) { index in
                    ZStack {
                        Capsule()
                            .fill(localCurrentIndex == index ? activeIndicator.color : indicator.color)
                        Capsule()
                            .strokeBorder(
                                localCurrentIndex == index ? activeIndicator.strokeColor : indicator.strokeColor,
                                style: StrokeStyle(lineWidth: localCurrentIndex == index
                                                   ? activeIndicator.strokeWidth
                                                   : indicator.strokeWidth)
                            )
                    }
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
            .onChangeOf(self.currentIndex) { newValue in
                if let animationDuration {
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        self.localCurrentIndex = newValue % originalCount
                    }
                } else {
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
    }
}

private extension PaywallComponent.CarouselComponent.AutoAdvanceTransitionType {

    static let `default`: PaywallComponent.CarouselComponent.AutoAdvanceTransitionType = .slide
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CarouselComponentView_Previews: PreviewProvider {

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {
        // Examples
        ScrollView {
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
                            padding: PaywallComponent.Padding(top: 6, bottom: 6, leading: 20, trailing: 20),
                            margin: PaywallComponent.Padding(top: 20, bottom: 20, leading: 0, trailing: 0),
                            backgroundColor: .init(light: .hex("#f0f0f0")),
                            shape: .pill,
                            border: nil,
                            shadow: .init(color: .init(light: .hex("#00000066")), radius: 4, x: 2, y: 2),
                            spacing: 10,
                            default: .init(
                                width: 10,
                                height: 10,
                                color: PaywallComponent.ColorScheme(light: .hex("#aeaeae")),
                                strokeColor: PaywallComponent.ColorScheme(light: .hex("#000000")),
                                strokeWidth: 0
                            ),
                            active: .init(
                                width: 10,
                                height: 10,
                                color: PaywallComponent.ColorScheme(light: .hex("#000000")),
                                strokeColor: PaywallComponent.ColorScheme(light: .hex("#FFFF00")),
                                strokeWidth: 0
                            )
                        )
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    colorScheme: .light
                ),
                onDismiss: {}
            )

            CarouselComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    component: .init(
                        padding: PaywallComponent.Padding(top: 20, bottom: 20, leading: 20, trailing: 20),
                        margin: PaywallComponent.Padding(top: 20, bottom: 20, leading: 20, trailing: 20),
                        background: .color(.init(light: .hex("#ffcc00"))),
                        shape: .rectangle(.init(topLeading: 20,
                                                topTrailing: 20,
                                                bottomLeading: 20,
                                                bottomTrailing: 20)),
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
                                backgroundColor: PaywallComponent.ColorScheme(light: .hex("#0000FF")),
                                shape: .rectangle(.init(topLeading: 8,
                                                        topTrailing: 8,
                                                        bottomLeading: 8,
                                                        bottomTrailing: 8))
                            )
                        ],
                        loop: true,
                        pageControl: .init(
                            position: .top,
                            padding: PaywallComponent.Padding(top: 10, bottom: 10, leading: 16, trailing: 16),
                            margin: PaywallComponent.Padding(top: 0, bottom: 10, leading: 0, trailing: 0),
                            backgroundColor: PaywallComponent.ColorScheme(light: .hex("#ffffff")),
                            shape: .rectangle(.init(topLeading: 8,
                                                    topTrailing: 8,
                                                    bottomLeading: 8,
                                                    bottomTrailing: 8)),
                            border: .init(color: .init(light: .hex("#cccccc")), width: 1),
                            shadow: nil,
                            spacing: 10,
                            default: .init(
                                width: 10,
                                height: 10,
                                color: PaywallComponent.ColorScheme(light: .hex("#cccccc")),
                                strokeColor: PaywallComponent.ColorScheme(light: .hex("#000000")),
                                strokeWidth: 0
                            ),
                            active: .init(
                                width: 10,
                                height: 10,
                                color: PaywallComponent.ColorScheme(light: .hex("#00000000")),
                                strokeColor: PaywallComponent.ColorScheme(light: .hex("#000000")),
                                strokeWidth: 1
                            )
                        )
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    colorScheme: .light
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
                        autoAdvance: .init(msTimePerPage: 1000, msTransitionTime: 500, transitionType: .fade),
                        pageControl: .init(
                            position: .bottom,
                            padding: PaywallComponent.Padding(top: 0, bottom: 0, leading: 0, trailing: 0),
                            margin: PaywallComponent.Padding(top: 10, bottom: 10, leading: 0, trailing: 0),
                            backgroundColor: nil,
                            shape: nil,
                            border: nil,
                            shadow: nil,
                            spacing: 10,
                            default: .init(
                                width: 10,
                                height: 10,
                                color: PaywallComponent.ColorScheme(light: .hex("#4462e96e")),
                                strokeColor: PaywallComponent.ColorScheme(light: .hex("#000000")),
                                strokeWidth: 0
                            ),
                            active: .init(
                                width: 60,
                                height: 20,
                                color: PaywallComponent.ColorScheme(light: .hex("#4462e9")),
                                strokeColor: PaywallComponent.ColorScheme(light: .hex("#000000")),
                                strokeWidth: 0
                            )
                        )
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    colorScheme: .light
                ),
                onDismiss: {}
            )
        }
        .padding(.vertical)
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Examples")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CarouselComponentViewModel {

    convenience init(
        component: PaywallComponent.CarouselComponent,
        localizationProvider: LocalizationProvider,
        colorScheme: ColorScheme
    ) throws {
        let viewModels: [StackComponentViewModel] = try component.pages.map { component in
            return try .init(
                component: component,
                localizationProvider: localizationProvider,
                colorScheme: colorScheme
            )
        }

        self.init(
            localizationProvider: localizationProvider,
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            component: component,
            pageStackViewModels: viewModels
        )
    }

}

#endif

#endif
