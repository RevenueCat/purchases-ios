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

    @State var size: CGSize = .zero

    @State var cachedURL: URL?
    @State var imageSource: PaywallComponent.ThemeImageUrls?

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
                )
            ) { style in
                if style.visible {
                    ZStack {
                        if let imageSource, let imageViewModel = try? ImageComponentViewModel(
                            localizationProvider: viewModel.localizationProvider,
                            uiConfigProvider: viewModel.uiConfigProvider,
                            component: .init(source: imageSource)
                        ) {
                            ImageComponentView(viewModel: imageViewModel)
                        }

                        if let cachedURL {
                            renderVideo(
                                VideoPlayerView(
                                    videoURL: cachedURL,
                                    shouldAutoPlay: style.autoPlay,
                                    contentMode: style.contentMode,
                                    showControls: style.showControls,
                                    loopVideo: style.loop,
                                    muteAudio: style.muteAudio
                                ),
                                size: size,
                                with: style
                            )
                        }
                    }
                    .onAppear {
                        self.imageSource = viewModel.imageSource
                        let fileRepository = FileRepository.shared

                        let resumeDownloadOfFullResolutionVideo: () -> Void = {
                            Task(priority: .userInitiated) {
                                do {
                                    // If the low res and normal resolution files were not yet found on disk
                                    // then we attempt to finish the download by calling the following method.
                                    // this method will share the async task that the cacheprewarming started
                                    // if it didn't error out, expediting the download time and reducing the memory
                                    // footprint of paywalls
                                    let url = try await fileRepository.generateOrGetCachedFileURL(for: style.url)
                                    guard url != cachedURL else { return }
                                    await MainActor.run {
                                        self.cachedURL = url
                                        self.imageSource = nil
                                    }
                                } catch {
                                    await MainActor.run {
                                        self.cachedURL = style.url
                                        self.imageSource = nil
                                    }
                                }
                            }
                        }

                        if let cachedURL = fileRepository.getCachedFileURL(for: style.url) {
                            self.cachedURL = cachedURL
                            self.imageSource = nil
                        } else if let lowResUrl = style.lowResUrl, lowResUrl != style.url {
                            let lowResCachedURL = fileRepository.getCachedFileURL(for: lowResUrl)
                            self.cachedURL = lowResCachedURL ?? lowResUrl
                            self.imageSource = nil
                            resumeDownloadOfFullResolutionVideo()
                        } else {
                            resumeDownloadOfFullResolutionVideo()
                        }
                    }
                    .applyMediaWidth(size: style.size)
                    .applyMediaHeight(size: style.size, aspectRatio: self.aspectRatio(style: style))
                    .padding(style.padding.extend(by: style.border?.width ?? 0))
                    .shape(border: style.border, shape: style.shape)
                    .clipped()
                    .shadow(style.shadow)
                    .padding(style.margin)
                }
            }
            .onSizeChange { size = $0 }

    }

    private func aspectRatio(style: VideoComponentStyle) -> Double {
        let (width, height) = self.videoSize(style: style)
        return Double(width) / Double(height)
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

    private func renderVideo<Video: View>(
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
            .applyIfLet(style.colorOverlay, apply: { view, colorOverlay in
                view.overlay(
                    Color.clear.backgroundStyle(.color(colorOverlay))
                )
            })
    }

    private func calculateMaxWidth(parentWidth: CGFloat, style: VideoComponentStyle) -> CGFloat {
        let totalBorderWidth = (style.border?.width ?? 0) * 2
        return parentWidth - totalBorderWidth
            - style.margin.leading - style.margin.trailing
            - style.padding.leading - style.padding.trailing
    }
}

#endif
