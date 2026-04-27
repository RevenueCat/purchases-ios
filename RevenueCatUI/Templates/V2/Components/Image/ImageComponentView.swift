//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ImageComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ImageComponentView: View {

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

    @Environment(\.customPaywallVariables)
    private var customVariables
    @Environment(\.selectedPackageId)
    private var selectedPackageId

    @Environment(\.requestSizeCalculation)
    private var requestSizeCalculation

    let viewModel: ImageComponentViewModel

    var renderForPreview: Bool {
        #if DEBUG
        return ProcessInfo.isRunningForPreviews
        #else
        false
        #endif
    }

    @State var size: CGSize?

    init(
        viewModel: ImageComponentViewModel,
        size: CGSize? = nil
    ) {
        self.viewModel = viewModel
        self._size = .init(initialValue: size ?? viewModel.cachedMeasuredSize)
    }

    var body: some View {
        let currentPackage = self.packageContext.package
        let isEligibleForIntroOffer = self.introOfferEligibilityContext.isEligible(
            package: currentPackage
        )
        let isEligibleForPromoOffer = self.paywallPromoOfferCache.isMostLikelyEligible(
            for: currentPackage
        )
        viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackageId: self.selectedPackageId,
            customVariables: self.customVariables,
            colorScheme: colorScheme
        ) { style in
            if style.visible {
                let expectedSize = CGSize(
                    width: self.imageSize(style: style).width,
                    height: self.imageSize(style: style).height
                )
                let effectiveSize = self.size ?? self.viewModel.cachedMeasuredSize
                let shouldForceSizeCalulation = {
                    if effectiveSize == nil {
                        return true
                    } else {
                        return requestSizeCalculation
                    }
                }()

                Group {
                    ZStack {
                        if shouldForceSizeCalulation {
                            // We cannot correctly render the image until we know the space the image can fill
                            // this will fill the space so we can get the correct measurements and render the image
                            self.decorate(Color.clear, with: style)
                        } else if renderForPreview {
                            #if DEBUG
                            self.decorate(
                                self.renderImage(
                                    DualColorImageGenerator.purpleOrangeWide.image.resizable(),
                                    effectiveSize ?? .zero,
                                    maxWidth: self.calculateMaxWidth(
                                        parentWidth: effectiveSize?.width ?? 0,
                                        style: style
                                    ),
                                    with: style
                                ),
                                with: style
                            )
                            #else
                            EmptyView()
                            #endif
                        } else {
                            self.decorate(
                                RemoteImage(
                                    url: style.url,
                                    lowResUrl: style.lowResUrl,
                                    darkUrl: style.darkUrl,
                                    darkLowResUrl: style.darkLowResUrl,
                                    // The expectedSize is important
                                    // It renders a clear image if actual image is being fetched
                                    expectedSize: expectedSize
                                ) { (image, size) in
                                    self.renderImage(
                                        image,
                                        size,
                                        maxWidth: self.calculateMaxWidth(
                                            parentWidth: effectiveSize?.width ?? 0,
                                            style: style
                                        ),
                                        with: style
                                    )
                                },
                                with: style
                            )
                        }
                    }
                    .onSizeChange { newSize in
                        let effectiveCurrentSize = self.size ?? self.viewModel.cachedMeasuredSize
                        guard effectiveCurrentSize != newSize else {
                            return
                        }

                        self.viewModel.cachedMeasuredSize = newSize
                        self.size = newSize
                    }
                }
            }
        }
    }

    private func decorate<Content: View>(
        _ content: Content,
        with style: ImageComponentStyle
    ) -> some View {
        content
            .applyMediaWidth(size: style.size)
            .applyMediaHeight(size: style.size, aspectRatio: self.aspectRatio(style: style))
            .applyIfLet(style.colorOverlay, apply: { view, colorOverlay in
                view.overlay(
                    Color.clear
                        .backgroundStyle(.color(colorOverlay))
                )
            })
            .clipped()
            .padding(style.padding.extend(by: style.border?.width ?? 0))
            .shape(border: style.border,
                   shape: style.shape)
            .compositingGroup() // ensure borders and images are a single layer that gets shaded.
            .applyIfLet(style.shadow, apply: { view, shadow in
                // We need to use the normal shadow modifier and not our custom one for png images
                view.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
            })
            .padding(style.margin)
    }

    private func calculateMaxWidth(parentWidth: CGFloat, style: ImageComponentStyle) -> CGFloat {
        let totalBorderWidth = (style.border?.width ?? 0) * 2
        let maxWidth = parentWidth - totalBorderWidth
            - style.margin.leading - style.margin.trailing
            - style.padding.leading - style.padding.trailing
        return max(0, maxWidth)
    }

    private func aspectRatio(style: ImageComponentStyle) -> Double {
        let (width, height) = self.imageSize(style: style)
        return Double(width) / Double(height)
    }

    private func imageSize(style: ImageComponentStyle) -> (width: Int, height: Int) {
        switch self.colorScheme {
        case .light:
            return (style.widthLight, style.heightLight)
        case .dark:
            return (style.widthDark ?? style.widthLight, style.heightDark ?? style.heightLight)
        @unknown default:
            return (style.widthLight, style.heightLight)
        }
    }

    private func renderImage(
        _ image: Image,
        _ size: CGSize,
        maxWidth: CGFloat,
        with style: ImageComponentStyle
    ) -> some View {
        image
            .fitToAspect(
                self.aspectRatio(style: style),
                contentMode: style.contentMode,
                containerContentMode: style.contentMode
            )
            .frame(maxWidth: maxWidth)
            // WIP: Fix this later when accessibility info is available
            .accessibilityHidden(true)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// swiftlint:disable:next type_body_length
struct ImageComponentView_Previews: PreviewProvider {
    static let catUrl = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!
    static let bigImageUrl = URL(string: "https://assets.pawwalls.com/1172568_1741034533.heic")!
    static let smallImage = URL(string: "https://assets.pawwalls.com/1172568_1734493671.heic")!

    @ViewBuilder
    static func imageView(
        url: URL,
        size: PaywallComponent.Size,
        fitMode: PaywallComponent.FitMode,
        width: Int,
        height: Int
    ) -> some View {
        let borderWidth: UInt = 4

        ImageComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [:]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    source: .init(
                        light: .init(
                            width: width,
                            height: height,
                            original: url,
                            heic: url,
                            heicLowRes: url
                        )
                    ),
                    size: size,
                    fitMode: fitMode,
                    border: .init(color: .init(light: .hex("#ff0000")), width: Double(borderWidth))
                )
            ),
            size: estimatedImageComponentSize(
                previewWidth: previewDimension,
                width: width,
                height: height,
                size: size,
                fitMode: fitMode,
                horizontalInsets: CGFloat(borderWidth) * 2,
                verticalInsets: CGFloat(borderWidth) * 2
            )
        )
        Text(.init("width: **\(size.width)** height: **\(size.height)**\n" +
                   "fitMode: **\(fitMode)**\n" +
                   "width: **\(width)** height: **\(height)**"))
    }

    // For the Emerge snapshot pipeline, we have to have the image available on first pass
    // This is for prepopulating the size of the view so the snapshot test can be taken
    // locally, the estimated size will be overwritten and the preview will render the
    // actual computed size.
    static func estimatedImageComponentSize(
        previewWidth: CGFloat,
        width: Int,
        height: Int,
        size: PaywallComponent.Size,
        fitMode: PaywallComponent.FitMode,
        horizontalInsets: CGFloat = 0,
        verticalInsets: CGFloat = 0
    ) -> CGSize {
        _ = fitMode

        let intrinsicWidth = max(CGFloat(width), 1)
        let intrinsicHeight = max(CGFloat(height), 1)
        let aspectRatio = intrinsicWidth / intrinsicHeight
        let availableContentWidth = max(0, previewWidth - horizontalInsets)

        let estimatedContentWidth: CGFloat
        switch size.width {
        case .fixed(let value):
            estimatedContentWidth = CGFloat(value)
        case .fill:
            estimatedContentWidth = availableContentWidth
        case .fit:
            switch size.height {
            case .fixed(let value):
                estimatedContentWidth = min(availableContentWidth, CGFloat(value) * aspectRatio)
            case .fit, .fill:
                estimatedContentWidth = min(availableContentWidth, intrinsicWidth)
            case .relative:
                estimatedContentWidth = min(availableContentWidth, intrinsicWidth)
            }
        case .relative(let value):
            estimatedContentWidth = max(0, availableContentWidth * CGFloat(value))
        }

        let estimatedContentHeight: CGFloat
        switch size.height {
        case .fixed(let value):
            estimatedContentHeight = CGFloat(value)
        case .fit, .fill:
            estimatedContentHeight = estimatedContentWidth / aspectRatio
        case .relative:
            estimatedContentHeight = estimatedContentWidth / aspectRatio
        }

        return CGSize(
            width: estimatedContentWidth + horizontalInsets,
            height: estimatedContentHeight + verticalInsets
        )
    }

    static var fixedHeight: UInt = 360
    static var previewDimension: CGFloat = 400

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        ScrollView {
            VStack {
                imageView(url: bigImageUrl,
                          size: .init(width: .fit, height: .fixed(fixedHeight)),
                          fitMode: .fit, width: 1080, height: 599)
                imageView(url: bigImageUrl,
                          size: .init(width: .fill, height: .fixed(fixedHeight)),
                          fitMode: .fit, width: 1080, height: 599)
                imageView(url: bigImageUrl,
                          size: .init(width: .fit, height: .fixed(fixedHeight)),
                          fitMode: .fill, width: 1080, height: 599)
                imageView(url: bigImageUrl,
                          size: .init(width: .fill, height: .fixed(fixedHeight)),
                          fitMode: .fill, width: 1080, height: 599)

                imageView(url: smallImage,
                          size: .init(width: .fit, height: .fixed(fixedHeight)),
                          fitMode: .fit, width: 22, height: 21)
                imageView(url: smallImage,
                          size: .init(width: .fill, height: .fixed(fixedHeight)),
                          fitMode: .fit, width: 22, height: 21)
                imageView(url: smallImage,
                          size: .init(width: .fill, height: .fixed(fixedHeight)),
                          fitMode: .fill, width: 22, height: 21)
                imageView(url: smallImage,
                          size: .init(width: .fit, height: .fixed(fixedHeight)),
                          fitMode: .fill, width: 22, height: 21)
            }.background(.blue)
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: previewDimension, height: previewDimension))
        .previewDisplayName("Image stretching horizontally beyond bounds")

        ScrollView {
            VStack {
                VStack {
                    imageView(url: smallImage,
                              size: .init(width: .fixed(32), height: .fit),
                              fitMode: .fill, width: 22, height: 21)
                }.frame(width: 300, height: 300).border(.green)

                VStack {
                    imageView(url: smallImage,
                              size: .init(width: .fixed(32), height: .fit),
                              fitMode: .fit, width: 22, height: 21)
                }.frame(width: 300, height: 300).border(.green)

                VStack {
                    imageView(url: smallImage,
                              size: .init(width: .fixed(32), height: .fill),
                              fitMode: .fill, width: 22, height: 21)
                }.frame(width: 300, height: 300).border(.green)

                VStack {
                    imageView(url: smallImage,
                              size: .init(width: .fixed(32), height: .fill),
                              fitMode: .fit, width: 22, height: 21)
                }.frame(width: 300, height: 300).border(.green)
            }.background(.blue)
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: previewDimension, height: previewDimension))
        .previewDisplayName("Image streching vertically when height=fit")

        // Light - Fill
        VStack {
            createImage(
                fitMode: .fit,
                maskShape: nil,
                colorOverlay: nil,
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
            createImage(
                fitMode: .fill,
                maskShape: nil,
                colorOverlay: nil,
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: previewDimension, height: previewDimension))
        .previewDisplayName("Light")

        // Light - Gradient
        VStack {
            createImage(
                fitMode: .fit,
                maskShape: nil,
                colorOverlay: .init(light: .linear(0, [
                    .init(color: "#ffffff", percent: 0),
                    .init(color: "#ffffff00", percent: 40)
                ])),
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
            createImage(
                fitMode: .fill,
                maskShape: nil,
                colorOverlay: .init(light: .linear(0, [
                    .init(color: "#ffffff", percent: 0),
                    .init(color: "#ffffff00", percent: 40)
                ])),
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: previewDimension, height: previewDimension))
        .previewDisplayName("Light - Gradient")

        // Light - Fit with Rounded Corner
        VStack {
            createImage(
                fitMode: .fit,
                maskShape: .rectangle(.init(topLeading: 40, topTrailing: 40, bottomLeading: 40, bottomTrailing: 40)),
                colorOverlay: nil,
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
            createImage(
                fitMode: .fill,
                maskShape: .rectangle(.init(topLeading: 40, topTrailing: 40, bottomLeading: 40, bottomTrailing: 40)),
                colorOverlay: nil,
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: previewDimension, height: previewDimension))
        .previewDisplayName("Light - Rounded Corner")

        // Light - Fit with Circle
        VStack {
            createImage(
                fitMode: .fit,
                maskShape: .circle,
                colorOverlay: nil,
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
            createImage(
                fitMode: .fill,
                maskShape: .circle,
                colorOverlay: nil,
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: previewDimension, height: previewDimension))
        .previewDisplayName("Light - Circle")

        // Light - Fit with Convex
        VStack {
            createImage(
                fitMode: .fit,
                maskShape: .convex,
                colorOverlay: nil,
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
            createImage(
                fitMode: .fill,
                maskShape: .convex,
                colorOverlay: nil,
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: previewDimension, height: previewDimension))
        .previewDisplayName("Light - Fit/Fill with Convex")

        // Light - Fit with Concave
        VStack {
            createImage(
                fitMode: .fit,
                maskShape: .concave,
                colorOverlay: nil,
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )

            createImage(
                fitMode: .fill,
                maskShape: .concave,
                colorOverlay: nil,
                border: .init(color: .init(light: .hex("#f8f81b")), width: 4),
                shadow: .init(
                    color: .init(
                        light: .hex("#000000"),
                        dark: .hex("#000000")
                    ),
                    radius: 5, x: 5, y: 5
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: previewDimension, height: previewDimension))
        .previewDisplayName("Light - Fit and Fill with Concave")
    }

    static func createImage(
        fitMode: PaywallComponent.FitMode,
        maskShape: PaywallComponent.MaskShape?,
        colorOverlay: PaywallComponent.ColorScheme?,
        border: PaywallComponent.Border?,
        shadow: PaywallComponent.Shadow?
    ) -> some View {
        ImageComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [:]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    source: .init(
                        light: .init(
                            width: 750,
                            height: 530,
                            original: catUrl,
                            heic: catUrl,
                            heicLowRes: catUrl
                        )
                    ),
                    size: .init(width: .fixed(200), height: .fixed(141)),
                    fitMode: fitMode,
                    maskShape: maskShape,
                    colorOverlay: colorOverlay,
                    border: border,
                    shadow: shadow
                )
            ),
            size: estimatedImageComponentSize(
                previewWidth: previewDimension,
                width: 750,
                height: 530,
                size: .init(width: .fixed(200), height: .fixed(200)),
                fitMode: .fill,
                horizontalInsets: CGFloat(8),
                verticalInsets: CGFloat(8)
            )
        )
    }
}

#endif

#endif
