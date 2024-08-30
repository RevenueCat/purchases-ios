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

    var component: PaywallComponent.StackComponent {
        return viewModel.component
    }

    var dimension: PaywallComponent.StackComponent.Dimension {
        component.dimension
    }

    var components: [PaywallComponent] {
        component.components
    }

    var spacing: CGFloat? {
        component.spacing
    }

    var backgroundColor: Color {
        component.backgroundColor?.toDyanmicColor() ?? Color.clear
    }

    var body: some View {
        switch dimension {
        case .vertical(let horizontalAlignment):
            VStack(alignment: horizontalAlignment.stackAlignment, spacing: spacing) {
                ComponentsView(componentViewModels: self.viewModel.viewModels)
            }
            .background(backgroundColor)
        case .horizontal(let verticalAlignment):
            HStack(alignment: verticalAlignment.stackAlignment, spacing: spacing) {
                ComponentsView(componentViewModels: self.viewModel.viewModels)
            }
            .background(backgroundColor)
        case .zlayer(let alignment):
            ZStack(alignment: alignment.stackAlignment) {
                ComponentsView(componentViewModels: self.viewModel.viewModels)
            }
            .background(backgroundColor)
        }
    }

}

#endif
