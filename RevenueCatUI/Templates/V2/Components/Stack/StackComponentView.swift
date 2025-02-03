//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponentView.swift
//
//  Created by James Borthwick on 2024-08-20.

import RevenueCat
import SwiftUI

// swiftlint:disable file_length

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct StackComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    private let viewModel: StackComponentViewModel
    private let onDismiss: () -> Void
    /// Used when this stack needs more padding than defined in the component, e.g. to avoid being drawn in the safe
    /// area when displayed as a sticky footer.
    private let additionalPadding: EdgeInsets

    init(
        viewModel: StackComponentViewModel,
        onDismiss: @escaping () -> Void,
        additionalPadding: EdgeInsets? = nil
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.additionalPadding = additionalPadding ?? EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    var body: some View {
        viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            )
        ) { style in
            self.make(style: style)
        }
    }

    @ViewBuilder
    private func make(style: StackComponentStyle) -> some View {
        Group {
            switch style.dimension {
            case .vertical(let horizontalAlignment, let distribution):
                VerticalStack(
                    style: style,
                    horizontalAlignment: horizontalAlignment,
                    distribution: distribution,
                    viewModels: self.viewModel.viewModels,
                    onDismiss: self.onDismiss
                )
                // This alignment positions the inner VStack horizontally and vertically
                .size(style.size,
                      horizontalAlignment: horizontalAlignment.frameAlignment,
                      verticalAlignment: distribution.verticalFrameAlignment)
            case .horizontal(let verticalAlignment, let distribution):
                HorizontalStack(
                    style: style,
                    verticalAlignment: verticalAlignment,
                    distribution: distribution,
                    viewModels: self.viewModel.viewModels,
                    onDismiss: self.onDismiss
                )
                // This alignment positions the inner VStack horizontally and vertically
                .size(style.size,
                      horizontalAlignment: distribution.horizontalFrameAlignment,
                      verticalAlignment: verticalAlignment.frameAlignment)
            case .zlayer(let alignment):
                // This alignment defines the position of inner components relative to each other
                ZStack(alignment: alignment.stackAlignment) {
                    ComponentsView(
                        componentViewModels: self.viewModel.viewModels,
                        ignoreSafeArea: self.viewModel.shouldApplySafeAreaInset,
                        onDismiss: self.onDismiss
                    )
                }
                // These alignments define the position of inner components inside the ZStack
                .size(style.size,
                      horizontalAlignment: alignment.stackAlignment,
                      verticalAlignment: alignment.stackAlignment)
            }
        }
        .padding(style.padding)
        .padding(additionalPadding)
        .shape(border: nil,
               shape: style.shape,
               background: style.backgroundStyle,
               uiConfigProvider: self.viewModel.uiConfigProvider)
        .apply(badge: style.badge, border: style.border, shadow: style.shadow, shape: style.shape)
        .padding(style.margin)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension View {

    // Helper to compute the order or application of border, shadow and badge.
    @ViewBuilder
    func apply(badge: BadgeModifier.BadgeInfo?,
               border: ShapeModifier.BorderInfo?,
               shadow: ShadowModifier.ShadowInfo?,
               shape: ShapeModifier.Shape?) -> some View {
        switch badge?.style {
        case .edgeToEdge:
            switch badge?.alignment {
            case .top, .bottom:
                // Some badge types require us to clip so they do not extend outside the bounds of the stack,
                // this requires the badge be added before the shadow so the shadow is not clipped.
                // However for edge-to-edge top/bottom badges, the shadow should be applied first so the badge
                // appears behind the shadow.
                self.shape(border: border, shape: shape)
                    .shadow(shadow: shadow, shape: shape?.toInsettableShape())
                    .stackBadge(badge)
            default:
                self.shape(border: border, shape: shape)
                    .stackBadge(badge)
                    .shadow(shadow: shadow, shape: shape?.toInsettableShape())
            }
        case .nested:
            // For nested badges, we want the border to be applied last so it appears over the badge.
            self.stackBadge(badge)
                .shape(border: border, shape: shape)
                .shadow(shadow: shadow, shape: shape?.toInsettableShape())
        default:
            self.shape(border: border, shape: shape)
                .stackBadge(badge)
                .shadow(shadow: shadow, shape: shape?.toInsettableShape())
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct VerticalStack: View {

    let style: StackComponentStyle
    let horizontalAlignment: PaywallComponent.HorizontalAlignment
    let distribution: PaywallComponent.FlexDistribution

    let viewModels: [PaywallComponentViewModel]
    let onDismiss: () -> Void

    var body: some View {
        // This is NOT a final implementation of this
        // There are some horizontal sizing issues with using LazyVStack
        // There are so performance issues with VStack with lots of children

        switch style.vstackStrategy {
        case .normal:
            // VStack when not many things
            VStack(
                // This alignment positions inner items horizontally relative to each other
                alignment: horizontalAlignment.stackAlignment,
                spacing: style.spacing
            ) {
                ComponentsView(
                    componentViewModels: self.viewModels,
                    onDismiss: self.onDismiss
                )
            }
        case .flex:
            FlexVStack(
                alignment: horizontalAlignment.stackAlignment,
                spacing: style.spacing,
                justifyContent: distribution.justifyContent,
                componentViewModels: self.viewModels,
                onDismiss: self.onDismiss
            )
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct HorizontalStack: View {

    let style: StackComponentStyle
    let verticalAlignment: PaywallComponent.VerticalAlignment
    let distribution: PaywallComponent.FlexDistribution

    let viewModels: [PaywallComponentViewModel]
    let onDismiss: () -> Void

    var body: some View {
        switch style.hstackStrategy {
        case .normal:
            HStack(
                // This alignment positions inner items vertically relative to each other
                alignment: verticalAlignment.stackAlignment,
                spacing: style.spacing
            ) {
                ComponentsView(componentViewModels: self.viewModels, onDismiss: self.onDismiss)
            }
        case .flex:
            FlexHStack(
                alignment: verticalAlignment.stackAlignment,
                spacing: style.spacing,
                justifyContent: distribution.justifyContent,
                componentViewModels: self.viewModels,
                onDismiss: self.onDismiss
            )
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// swiftlint:disable:next type_body_length
struct StackComponentView_Previews: PreviewProvider {
    static var previews: some View {
        // Default - Fill
        StackComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    components: [
                        .text(.init(
                            text: "text_1",
                            color: .init(light: .hex("#000000"))))
                    ],
                    size: .init(
                        width: .fill,
                        height: .fit
                    ),
                    backgroundColor: .init(light: .hex("#ff0000"))
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "text_1": .string("Hey")
                    ]
                )
            ),
            onDismiss: {}
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default - Fill")

        // Default - Fit
        StackComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    components: [
                        .text(.init(
                            text: "text_1",
                            color: .init(light: .hex("#000000"))))
                    ],
                    size: .init(
                        width: .fit,
                        height: .fit
                    ),
                    backgroundColor: .init(light: .hex("#ff0000"))
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "text_1": .string("Hey")
                    ]
                )
            ),
            onDismiss: {}
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default - Fit")

        // Default - Fill Fit Fixed Fill
        HStack(spacing: 0) {
            StackComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    component: .init(
                        components: [
                            .text(.init(
                                text: "text_1",
                                color: .init(light: .hex("#000000"))))
                        ],
                        size: .init(
                            width: .fill,
                            height: .fit
                        ),
                        backgroundColor: .init(light: .hex("#ff0000"))
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "text_1": .string("Hey")
                        ]
                    )
                ),
                onDismiss: {}
            )

            StackComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    component: .init(
                        components: [
                            .text(.init(
                                text: "text_1",
                                color: .init(light: .hex("#000000"))))
                        ],
                        size: .init(
                            width: .fit,
                            height: .fit
                        ),
                        backgroundColor: .init(light: .hex("#0000ff"))
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "text_1": .string("Hey")
                        ]
                    )
                ),
                onDismiss: {}
            )

            StackComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    component: .init(
                        components: [
                            .text(.init(
                                text: "text_1",
                                color: .init(light: .hex("#000000"))))
                        ],
                        size: .init(
                            width: .fixed(100),
                            height: .fit
                        ),
                        backgroundColor: .init(light: .hex("#00ff00"))
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "text_1": .string("Hey")
                        ]
                    )
                ),
                onDismiss: {}
            )

            StackComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    component: .init(
                        components: [
                            .text(.init(
                                text: "text_1",
                                color: .init(light: .hex("#000000"))))
                        ],
                        size: .init(
                            width: .fill,
                            height: .fit
                        ),
                        backgroundColor: .init(light: .hex("#ff0000"))
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "text_1": .string("Hey")
                        ]
                    )
                ),
                onDismiss: {}
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default - Fill Fit Fixed Fill")

        // Fits don't expand
        StackComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    components: [
                        .stack(PaywallComponent.StackComponent(
                            components: [
                                .text(PaywallComponent.TextComponent(
                                    text: "text_1",
                                    color: .init(light: .hex("#000000")),
                                    backgroundColor: .init(light: .hex("#ffcc00")),
                                    size: .init(width: .fit, height: .fit),
                                    margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10)
                                )),
                                .stack(PaywallComponent.StackComponent(
                                    components: [
                                        .text(.init(
                                            text: "text_1",
                                            color: .init(light: .hex("#000000")),
                                            backgroundColor: .init(light: .hex("#ffcc00")),
                                            size: .init(width: .fit, height: .fit),
                                            margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10)
                                        ))
                                    ],
                                    dimension: .vertical(.center, .center),
                                    size: .init(width: .fit, height: .fit),
                                    backgroundColor: .init(light: .hex("#dedede")),
                                    margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10)
                                )),
                                .stack(PaywallComponent.StackComponent(
                                    components: [
                                        .text(.init(
                                            text: "text_1",
                                            color: .init(light: .hex("#000000")),
                                            backgroundColor: .init(light: .hex("#ffcc00")),
                                            size: .init(width: .fit, height: .fit),
                                            margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10)
                                        ))
                                    ],
                                    dimension: .horizontal(.center, .center),
                                    size: .init(width: .fit, height: .fit),
                                    backgroundColor: .init(light: .hex("#dedede")),
                                    margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10)
                                ))
                            ],
                            dimension: .vertical(.center, .center),
                            size: .init(width: .fit, height: .fit),
                            backgroundColor: .init(light: .hex("#0000ff")),
                            margin: .init(top: 10, bottom: 10, leading: 10, trailing: 10)
                        ))
                    ],
                    dimension: .vertical(.center, .center),
                    size: .init(
                        width: .fill,
                        height: .fill
                    ),
                    backgroundColor: .init(light: .hex("#ff0000"))
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "text_1": .string("Hey")
                    ]
                )
            ),
            onDismiss: {}
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Fits don't expand")

        stackAlignmentAndDistributionPreviews()
    }

    @ViewBuilder
    static func stackAlignmentAndDistributionPreviews() -> some View {
        let dimensions: [PaywallComponent.Dimension] = [
            .horizontal(.top, .start),
            .horizontal(.center, .center),
            .horizontal(.bottom, .end),
            .horizontal(.top, .spaceAround),
            .horizontal(.center, .spaceBetween),
            .horizontal(.bottom, .spaceEvenly),
            .vertical(.leading, .start),
            .vertical(.center, .center),
            .vertical(.trailing, .end),
            .vertical(.leading, .spaceAround),
            .vertical(.center, .spaceBetween),
            .vertical(.trailing, .spaceEvenly)
        ]
        ForEach(dimensions, id: \.self) { dimension in
            StackComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! StackComponentViewModel(
                    component: PaywallComponent.StackComponent(
                        components: innerStacks(dimension: dimension),
                        dimension: dimension,
                        size: .init(width: .fill, height: .fixed(150)),
                        spacing: 10,
                        backgroundColor: .init(light: .hex("#ff0000")),
                        padding: .init(top: 10, bottom: 10, leading: 10, trailing: 10)
                    ),
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    )
                ),
                onDismiss: {}
            )
            .previewRequiredEnvironmentProperties()
            .previewLayout(.sizeThatFits)
            .previewDisplayName(displayName(dimension: dimension))
        }
    }

    static func displayName(dimension: PaywallComponent.Dimension) -> String {
        switch dimension {
        case .vertical(let horizontalAlignment, let flexDistribution):
            return "Vertical (\(horizontalAlignment.rawValue), \(flexDistribution.rawValue))"
        case .horizontal(let verticalAlignment, let flexDistribution):
            return "Horizontal (\(verticalAlignment.rawValue), \(flexDistribution.rawValue))"
        case .zlayer:
            return ""
        @unknown default:
            return ""
        }
    }

    static func innerStacks(dimension: PaywallComponent.Dimension) -> [PaywallComponent] {
        var sizes: [PaywallComponent.Size]
        switch dimension {
        case .vertical:
            sizes = [
                .init(width: .fixed(100), height: .fixed(20)),
                .init(width: .fixed(50), height: .fixed(20)),
                .init(width: .fixed(70), height: .fixed(20))
            ]
        case .horizontal:
            sizes = [
                .init(width: .fixed(20), height: .fixed(100)),
                .init(width: .fixed(20), height: .fixed(50)),
                .init(width: .fixed(20), height: .fixed(70))
            ]
        case .zlayer:
            sizes = []
        @unknown default:
            sizes = []
        }
        return sizes.map { size in
            .stack(.init(components: [], size: size, backgroundColor: .init(light: .hex("#ffcc00"))))
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension StackComponentViewModel {

    convenience init(
        component: PaywallComponent.StackComponent,
        localizationProvider: LocalizationProvider
    ) throws {
        let validator = PackageValidator()
        let factory = ViewModelFactory()
        let offering = Offering(identifier: "", serverDescription: "", availablePackages: [])
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())

        let viewModels = try component.components.map { component in
            try factory.toViewModel(
                component: component,
                packageValidator: validator,
                firstImageInfo: nil,
                offering: offering,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider
            )
        }

        let badgeViewModels = try component.badge?.stack.components.map { component in
            try factory.toViewModel(
                component: component,
                packageValidator: validator,
                firstImageInfo: nil,
                offering: offering,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider
            )
        }

        try self.init(
            component: component,
            viewModels: viewModels,
            badgeViewModels: badgeViewModels ?? [],
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            localizationProvider: localizationProvider
        )
    }

}

#endif

#endif
