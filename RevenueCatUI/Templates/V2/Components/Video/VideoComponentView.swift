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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

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
                Color.clear
                    .task {
                        self.imageSource = viewModel.imageSource
                        let fileRepository = FileRepository()
                        if let lowResUrl = style.lowResUrl {
                            let lowResCachedURL = try? await fileRepository.generateOrGetCachedFileURL(for: lowResUrl)
                            self.cachedURL = lowResCachedURL
                        }
                        let cachedURL = try? await fileRepository.generateOrGetCachedFileURL(for: style.url)
                        self.cachedURL = cachedURL ?? style.url
                        self.imageSource = nil
                    }
                if style.visible {
                    ZStack {
                        if let cachedURL {
                            renderVideo(
                                VideoPlayerView(
                                    videoURL: cachedURL,
                                    shouldAutoPlay: style.autoplay,
                                    contentMode: style.contentMode,
                                    showControls: style.showControls,
                                    loopVideo: style.loop,
                                    muteAudio: style.muteAudio
                                ),
                                size: size,
                                with: style
                            )
                        } else if let imageSource, let imageViewModel = try? ImageComponentViewModel(
                            localizationProvider: viewModel.localizationProvider,
                            uiConfigProvider: viewModel.uiConfigProvider,
                            component: .init(source: imageSource)
                        ) {
                            ImageComponentView(viewModel: imageViewModel)
                        }

                    }
                    .applyVideoWidth(size: style.size)
                    .applyVideoHeight(size: style.size, aspectRatio: self.aspectRatio(style: style))
                    .clipped()
                    .shape(border: style.border,
                           shape: style.shape)
                    .shadow(shadow: style.shadow,
                            shape: style.shape?.toInsettableShape())
                    .padding(style.padding.extend(by: style.border?.width ?? 0))
                    .padding(style.margin)
                }
            }
            .sizeReader($size)

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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension View {

    @ViewBuilder
    func applyVideoWidth(size: PaywallComponent.Size) -> some View {
        switch size.width {
        case .fit:
            self
        case .fill:
            self.frame(maxWidth: .infinity)
        case .fixed(let value):
            self.frame(width: Double(value))
        default:
            self
        }
    }

    @ViewBuilder
    func applyVideoHeight(size: PaywallComponent.Size, aspectRatio: Double) -> some View {
        switch size.height {
        case .fit:
            switch size.width {
            case .fit:
                self
            case .fill:
                self
            case .fixed(let value):
                // This is the only change versus the regular .size() modifier.
                // When the image has height=fit and fixed width, we manually set a
                // fixed height according to the aspect ratio.
                // Otherwise the view would grow vertically to occupy available space.
                // See "Image streching vertically" preview
                self.frame(height: Double(value) / aspectRatio)
            default:
                self
            }
        case .fill:
            self.frame(maxHeight: .infinity)
        case .fixed(let value):
            self.frame(height: Double(value))
        default:
            self
        }
    }

}

#endif
