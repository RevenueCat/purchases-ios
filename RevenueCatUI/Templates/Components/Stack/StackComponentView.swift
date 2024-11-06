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
                // LazyVStack needed for performance when loading
                LazyVStack(spacing: viewModel.spacing) {
                    ComponentsView(componentViewModels: self.viewModel.viewModels, onDismiss: self.onDismiss)
                    .frame(maxWidth: .infinity, alignment: horizontalAlignment.stackAlignment)
                }
            case .horizontal(let verticalAlignment):
                HStack(alignment: verticalAlignment.stackAlignment, spacing: viewModel.spacing) {
                    ComponentsView(componentViewModels: self.viewModel.viewModels, onDismiss: self.onDismiss)
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

struct WidthModifier: ViewModifier {
    var width: PaywallComponent.WidthSize?

    func body(content: Content) -> some View {
        if let width = width {
            switch width.type {
            case .fit:
                content
            case .fill:
                content
                    .frame(maxWidth: .infinity)
            case .fixed:
                if let value = width.value {
                    content
                        .frame(width: CGFloat(value))
                } else {
                    content
                }
            }
        } else {
            content
        }
    }
}

extension View {

    func width(_ width: PaywallComponent.WidthSize? = nil) -> some View {
        self.modifier(WidthModifier(width: width))
    }

}

#endif
