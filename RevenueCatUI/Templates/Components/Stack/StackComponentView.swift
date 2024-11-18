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

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct StackComponentView: View {

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    private let viewModel: StackComponentViewModel
    private let onDismiss: () -> Void
    /// Used when this stack needs more padding than defined in the component, e.g. to avoid being drawn in the safe
    /// area when displayed as a sticky footer.
    private let additionalPadding: EdgeInsets

    init(viewModel: StackComponentViewModel, onDismiss: @escaping () -> Void, additionalPadding: EdgeInsets? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.additionalPadding = additionalPadding ?? EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    var body: some View {
        viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition
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
            case .horizontal(let verticalAlignment, let distribution):
                HorizontalStack(
                    style: style,
                    verticalAlignment: verticalAlignment,
                    distribution: distribution,
                    viewModels: self.viewModel.viewModels,
                    onDismiss: self.onDismiss
                )
            case .zlayer(let alignment):
                ZStack(alignment: alignment.stackAlignment) {
                    ComponentsView(componentViewModels: self.viewModel.viewModels, onDismiss: self.onDismiss)
                }
            }
        }
        .padding(style.padding)
        .padding(additionalPadding)
        .size(style.size)
        .background(style.backgroundColor)
        .shape(border: style.border,
               shape: style.shape)
        .applyIfLet(style.shadow) { view, shadow in
            // Without compositingGroup(), the shadow is applied to the stack's children as well.
            view.compositingGroup().shadow(shadow: shadow)
        }
        .padding(style.margin)
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
                alignment: horizontalAlignment.stackAlignment,
                spacing: style.spacing
            ) {
                ComponentsView(
                    componentViewModels: self.viewModels,
                    onDismiss: self.onDismiss
                )
            }
        case .lazy:
            // LazyVStack needed for performance when loading
            LazyVStack(
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
        case .normal, .lazy:
            HStack(alignment: verticalAlignment.stackAlignment, spacing: style.spacing) {
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
                localizedStrings: [
                    "text_1": .string("Hey")
                ]),
            onDismiss: {}
        )
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
                localizedStrings: [
                    "text_1": .string("Hey")
                ]),
            onDismiss: {}
        )
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
                    localizedStrings: [
                        "text_1": .string("Hey")
                    ]),
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
                    localizedStrings: [
                        "text_1": .string("Hey")
                    ]),
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
                    localizedStrings: [
                        "text_1": .string("Hey")
                    ]),
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
                    localizedStrings: [
                        "text_1": .string("Hey")
                    ]),
                onDismiss: {}
            )
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default - Fill Fit Fixed Fill")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension StackComponentViewModel {

    convenience init(
        component: PaywallComponent.StackComponent,
        localizedStrings: PaywallComponent.LocalizationDictionary
    ) throws {
        let validator = PackageValidator()
        let factory = ViewModelFactory()
        let offering = Offering(identifier: "", serverDescription: "", availablePackages: [])

        let viewModels = try component.components.map { component in
            try factory.toViewModel(
                component: component,
                packageValidator: validator,
                offering: offering,
                localizedStrings: localizedStrings
            )
        }

        try self.init(
            component: component,
            viewModels: viewModels
        )
    }

}

#endif

#endif
