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

    var body: some View {
        Group {
            switch viewModel.dimension {
            case .vertical(let horizontalAlignment):
                // LazyVStack needed for performance when loading
                LazyVStack(spacing: viewModel.spacing) {
                    Group {
                        ComponentsView(componentViewModels: self.viewModel.viewModels)
                    }
                    .frame(maxWidth: .infinity, alignment: horizontalAlignment.stackAlignment)
                }
            case .horizontal(let verticalAlignment):
                HStack(alignment: verticalAlignment.stackAlignment, spacing: viewModel.spacing) {
                    ComponentsView(componentViewModels: self.viewModel.viewModels)
                }
            case .zlayer(let alignment):
                ZStack(alignment: alignment.stackAlignment) {
                    ComponentsView(componentViewModels: self.viewModel.viewModels)
                }
            }
        }
        .padding(viewModel.padding)
        .width(viewModel.width)
        .background(viewModel.backgroundColor)
        .roundedCorner(viewModel.cornerRadiuses.topLeading, corners: .topLeft)
        .roundedCorner(viewModel.cornerRadiuses.topTrailing, corners: .topRight)
        .roundedCorner(viewModel.cornerRadiuses.bottomLeading, corners: .bottomLeft)
        .roundedCorner(viewModel.cornerRadiuses.bottomTrailing, corners: .bottomRight)
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
