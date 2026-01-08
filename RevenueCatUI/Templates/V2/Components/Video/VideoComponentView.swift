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

    @State private var stagedURL: URL?
    @State private var cachedURL: URL?
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
                ),
                colorScheme: colorScheme
            ) { style in
                if style.visible {
                    let viewData = style.viewData(forDarkMode: colorScheme == .dark)

                    ZStack {
                        if imageSource == nil && cachedURL == nil {
                            // greedily fill space while loading occurs
                            render(Color.clear, size: size, with: style)
                        }

                        if let imageSource, let imageViewModel = try? ImageComponentViewModel(
                            localizationProvider: viewModel.localizationProvider,
                            uiConfigProvider: viewModel.uiConfigProvider,
                            component: .init(source: imageSource, fitMode: style.contentMode == .fill ? .fill : .fit)
                        ) {
                            ImageComponentView(viewModel: imageViewModel)
                        }

                        if let cachedURL {
                            render(
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
                        let fileRepository = FileRepository.shared

                        let resumeDownloadOfFullResolutionVideo: () -> Void = {
                            Task(priority: .userInitiated) {
                                do {
                                    // If the low res and normal resolution files were not yet found on disk
                                    // then we attempt to finish the download by calling the following method.
                                    // this method will share the async task that the cacheprewarming started
                                    // if it didn't error out, expediting the download time and reducing the memory
                                    // footprint of paywalls
                                    let url = try await fileRepository
                                        .generateOrGetCachedFileURL(
                                            for: viewData.url,
                                            withChecksum: viewData.checksum
                                        )
                                    guard url != cachedURL, !Task.isCancelled else { return }
                                    await MainActor.run {
                                        self.stagedURL = url
                                    }
                                } catch {
                                    await MainActor.run {
                                        self.stagedURL = viewData.url
                                    }
                                }
                            }
                        }

                        if let cachedURL = fileRepository.getCachedFileURL(
                            for: viewData.url,
                            withChecksum: viewData.checksum
                        ) {
                            self.cachedURL = cachedURL
                            // If we have a cached video, no need to display a fallback image
                            self.imageSource = nil
                        } else if let lowResUrl = viewData.lowResUrl, lowResUrl != viewData.url {
                            let lowResCachedURL = fileRepository.getCachedFileURL(
                                for: lowResUrl,
                                withChecksum: viewData.lowResChecksum
                            )
                            self.cachedURL = lowResCachedURL ?? lowResUrl

                            if lowResCachedURL == nil {
                                // Display the fallback image while loading takes place
                                self.imageSource = viewModel.imageSource
                            }

                            resumeDownloadOfFullResolutionVideo()
                        } else {
                            // Display the fallback image while loading takes place
                            self.imageSource = viewModel.imageSource
                            resumeDownloadOfFullResolutionVideo()
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
                    .onChangeCompat(of: stagedURL) { newValue in
                        // FIX: Using .onChange instead of .onReceive(stagedURL.publisher...)
                        // because .publisher on Optional doesn't observe @State changes
                        guard let newURL = newValue, newURL != cachedURL else { return }
                        self.cachedURL = newURL
                        self.imageSource = nil
                    }
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

// MARK: - onChange Compatibility

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension View {
    @ViewBuilder
    func onChangeCompat<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value) { newValue in
                action(newValue)
            }
        }
    }
}

#endif
