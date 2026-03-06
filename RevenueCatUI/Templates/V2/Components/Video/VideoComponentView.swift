//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VideoComponent.swift
//
//  Created by Jacob Zivan Rakidzich on 8/18/25.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct VideoComponentView: View {
    let viewModel: VideoComponentViewModel

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

    @Environment(\.carouselState)
    private var carouselState

    @Environment(\.customPaywallVariables)
    private var customVariables
    @Environment(\.selectedPackageId)
    private var selectedPackageId

    @State var size: CGSize = .zero

    @State private var cachedURL: URL?
    @State var imageSource: PaywallComponent.ThemeImageUrls?

    /// Tracks whether this page is active or adjacent in a carousel.
    /// Updated via onChange to ensure SwiftUI detects the change.
    @State private var isPlayable: Bool = true

    /// Toggled when transitioning from non-playable to playable state.
    /// Used as part of the VideoPlayerView's identity to force recreation,
    /// ensuring autoplay triggers correctly when the page becomes visible again.
    @State private var playerRefreshToggle: Bool = false

    var body: some View {
        viewModel
            .styles(
                state: componentViewState,
                condition: screenCondition,
                isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                    package: self.packageContext.package
                ),
                isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(
                    for: self.packageContext.package
                ),
                selectedPackageId: self.selectedPackageId,
                customVariables: self.customVariables,
                colorScheme: colorScheme
            ) { style in
                if style.visible {
                    let viewData = style.viewData(forDarkMode: colorScheme == .dark)

                    ZStack {
                        // Determine if video player will render
                        let willShowVideo = cachedURL != nil && isPlayable

                        // Always render spacer for sizing (needed for fixed-size videos)
                        render(Color.clear, size: size, with: style)

                        // Always show thumbnail as base layer while video loads/prepares
                        if let thumbnailSource = imageSource ?? viewModel.imageSource,
                           let imageViewModel = try? ImageComponentViewModel(
                            localizationProvider: viewModel.localizationProvider,
                            uiConfigProvider: viewModel.uiConfigProvider,
                            component: .init(
                                source: thumbnailSource,
                                fitMode: style.contentMode == .fill ? .fill : .fit
                            )
                        ) {
                            ImageComponentView(viewModel: imageViewModel)
                        }

                        // Only create VideoPlayerView when on active carousel page (or not in carousel)
                        // This prevents multiple AVPlayer instances from competing for resources
                        // Video layers on top of thumbnail once ready
                        if let cachedURL, willShowVideo {
                            render(
                                VideoPlayerView(
                                    videoURL: cachedURL,
                                    shouldAutoPlay: style.autoPlay,
                                    contentMode: style.contentMode,
                                    showControls: style.showControls,
                                    loopVideo: style.loop,
                                    muteAudio: style.muteAudio
                                )
                                // Recreate player when becoming playable again (carousel navigation).
                                // swiftlint:disable:next todo
                                // TODO: Add cachedURL back to .id() once AVPlayer can swap
                                // URLs mid-playback without visible stuttering.
                                .id(playerRefreshToggle),
                                size: size,
                                with: style
                            )
                            .transition(.opacity.animation(.easeIn(duration: 0.3)))
                        }
                    }
                    .onAppear {
                        let fileRepository = FileRepository.shared

                        // 1. High-res cached → use immediately
                        if let fullResCachedURL = fileRepository.getCachedFileURL(
                            for: viewData.url,
                            withChecksum: viewData.checksum
                        ) {
                            self.cachedURL = fullResCachedURL
                            self.imageSource = nil
                            return
                        }

                        // 2. Low-res cached → use immediately, cache high-res in background
                        if let lowResUrl = viewData.lowResUrl,
                           lowResUrl != viewData.url,
                           let lowResCachedURL = fileRepository.getCachedFileURL(
                               for: lowResUrl,
                               withChecksum: viewData.lowResChecksum
                           ) {
                            self.cachedURL = lowResCachedURL
                            self.imageSource = nil
                            cacheVideo(fileRepository: fileRepository, url: viewData.url, checksum: viewData.checksum)
                            return
                        }

                        // 3. Nothing cached → stream remote URL, cache in background
                        self.cachedURL = viewData.url
                        self.imageSource = viewModel.imageSource

                        // Cache both resolutions as a failsafe: if the high-res
                        // download fails or is canceled, the low-res version is
                        // available as a fallback on next open.
                        cacheVideo(fileRepository: fileRepository, url: viewData.url, checksum: viewData.checksum)
                        if let lowResUrl = viewData.lowResUrl, lowResUrl != viewData.url {
                            cacheVideo(
                                fileRepository: fileRepository,
                                url: lowResUrl,
                                checksum: viewData.lowResChecksum
                            )
                        }
                    }
                    .applyMediaWidth(size: style.size)
                    .applyMediaHeight(size: style.size, aspectRatio: self.aspectRatio(style: style))
                    .applyIfLet(style.colorOverlay, apply: { view, colorOverlay in
                        view.overlay(
                            Color.clear.backgroundStyle(.color(colorOverlay))
                                .allowsHitTesting(false)
                        )
                    })
                    .padding(style.padding.extend(by: style.border?.width ?? 0))
                    .shape(border: style.border, shape: style.shape)
                    .clipped()
                    .shadow(shadow: style.shadow, shape: style.shape?.toInsettableShape(size: size))
                    .padding(style.margin)
                }
            }
            .onSizeChange { size = $0 }
            .onAppear {
                updatePlayableState(isPlayable: carouselState?.isActiveOrNeighbor ?? true)
            }
            .onChangeOf(carouselState) { newState in
                updatePlayableState(isPlayable: newState?.isActiveOrNeighbor ?? true)
            }

    }

    private func aspectRatio(style: VideoComponentStyle) -> Double {
        let (width, height) = self.videoSize(style: style)
        return Double(width) / Double(height)
    }

    private func updatePlayableState(isPlayable newValue: Bool) {
        if !self.isPlayable && newValue {
            self.playerRefreshToggle.toggle()
        }
        self.isPlayable = newValue
    }

    private func videoSize(style: VideoComponentStyle) -> (width: Int, height: Int) {
        switch self.colorScheme {
        case .light:
            return (style.widthLight, style.heightLight)
        case .dark:
            return (style.widthDark ?? style.widthLight, style.heightDark ?? style.heightLight)
        @unknown default:
            return (style.widthLight, style.heightLight)
        }
    }

    private func cacheVideo(fileRepository: FileRepository, url: URL, checksum: Checksum?) {
        Task(priority: .utility) {
            do {
                _ = try await fileRepository.generateOrGetCachedFileURL(
                    for: url,
                    withChecksum: checksum
                )
            } catch {
                Logger.warning(
                    Strings.video_failed_to_cache(url, error)
                )
            }
        }
    }

    private func render<Video: View>(
        _ video: Video,
        size: CGSize,
        with style: VideoComponentStyle
    ) -> some View {
        video
            .frame(maxWidth: calculateMaxWidth(parentWidth: size.width, style: style))
            .fitToAspectRatio(
                aspectRatio: aspectRatio(style: style),
                contentMode: .fill, // This must be set to fill for the modifier to work correctly
                containerContentMode: style.contentMode // the container is what truly controls this
            )
    }

    private func calculateMaxWidth(parentWidth: CGFloat, style: VideoComponentStyle) -> CGFloat {
        let totalBorderWidth = (style.border?.width ?? 0) * 2
        return parentWidth - totalBorderWidth
            - style.margin.leading - style.margin.trailing
            - style.padding.leading - style.padding.trailing
    }
}

#endif
