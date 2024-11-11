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

    let viewModel: StackComponentViewModel
    let onDismiss: () -> Void
    /// Used when this stack needs more padding than defined in the component, e.g. to avoid being drawn in the safe
    /// area when displayed as a sticky footer.
    let additionalPadding: EdgeInsets

    init(viewModel: StackComponentViewModel, onDismiss: @escaping () -> Void, additionalPadding: EdgeInsets? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.additionalPadding = additionalPadding ?? EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    var body: some View {
        Group {
            switch viewModel.dimension {
            case .vertical(let horizontalAlignment):
                Group {
                    // This is NOT a final implementation of this
                    // There are some horizontal sizing issues with using LazyVStack
                    // There are so performance issues with VStack with lots of children
                    if viewModel.shouldUseVStack {
                        // VStack when not many things
                        VStack(
                            alignment: horizontalAlignment.stackAlignment,
                            spacing: viewModel.spacing
                        ) {
                            ComponentsView(
                                componentViewModels: self.viewModel.viewModels,
                                onDismiss: self.onDismiss
                            )
                        }
                    } else {
                        // LazyVStack needed for performance when loading
                        LazyVStack(
                            alignment: horizontalAlignment.stackAlignment,
                            spacing: viewModel.spacing
                        ) {
                            ComponentsView(
                                componentViewModels: self.viewModel.viewModels,
                                onDismiss: self.onDismiss
                            )
                        }
                    }
                }
                .applyIf(viewModel.shouldUseFlex) {
                    $0.frame(
                        maxWidth: .infinity,
                        alignment: horizontalAlignment.frameAlignment
                    )
                }
            case .horizontal(let verticalAlignment, let distribution):
                if viewModel.shouldUseFlex {
                    FlexHStack(
                        alignment: verticalAlignment.stackAlignment,
                        spacing: viewModel.spacing,
                        justifyContent: distribution.justifyContent,
                        componentViewModels: self.viewModel.viewModels,
                        onDismiss: self.onDismiss
                    )
                } else {
                    HStack(alignment: verticalAlignment.stackAlignment, spacing: viewModel.spacing) {
                        ComponentsView(componentViewModels: self.viewModel.viewModels, onDismiss: self.onDismiss)
                    }
                }
            case .zlayer(let alignment):
                ZStack(alignment: alignment.stackAlignment) {
                    ComponentsView(componentViewModels: self.viewModel.viewModels, onDismiss: self.onDismiss)
                }
            }
        }
        .padding(viewModel.padding)
        .padding(additionalPadding)
        .width(viewModel.width)
        .background(viewModel.backgroundColor)
        .cornerBorder(border: viewModel.border,
                      radiuses: viewModel.cornerRadiuses)
        .applyIfLet(viewModel.shadow) { view, shadow in
            // Without compositingGroup(), the shadow is applied to the stack's children as well.
            view.compositingGroup().shadow(shadow: shadow)
        }
        .padding(viewModel.margin)
    }

}

extension PaywallComponent.FlexDistribution {

    var justifyContent: JustifyContent {
        switch self {
        case .start:
            return .start
        case .center:
            return .center
        case .end:
            return .end
        case .spaceBetween:
            return .spaceBetween
        case .spaceAround:
            return .spaceAround
        case .spaceEvenly:
            return .spaceEvenly
        }
    }

}

struct WidthModifier: ViewModifier {

    var sizeConstraint: PaywallComponent.SizeConstraint

    func body(content: Content) -> some View {
        switch self.sizeConstraint {
        case .fit:
            content
        case .fill:
            content
                .frame(maxWidth: .infinity)
        case .fixed(let value):
            content
                .frame(width: CGFloat(value))
        }
    }

}

extension View {

    func width(_ sizeConstraint: PaywallComponent.SizeConstraint) -> some View {
        self.modifier(WidthModifier(sizeConstraint: sizeConstraint))
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

        self.init(
            component: component,
            viewModels: viewModels
        )
    }

}

#endif

#endif
