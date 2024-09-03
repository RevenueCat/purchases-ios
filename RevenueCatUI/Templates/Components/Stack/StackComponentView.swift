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
        switch viewModel.dimension {
        case .vertical(let horizontalAlignment):
            VStack(alignment: horizontalAlignment.stackAlignment, spacing: viewModel.spacing) {
                ComponentsView(componentViewModels: self.viewModel.viewModels)
            }
            .background(viewModel.backgroundColor)
            .padding(viewModel.padding)
        case .horizontal(let verticalAlignment):
            HStack(alignment: verticalAlignment.stackAlignment, spacing: viewModel.spacing) {
                ComponentsView(componentViewModels: self.viewModel.viewModels)
            }
            .background(viewModel.backgroundColor)
            .padding(viewModel.padding)
        case .zlayer(let alignment):
            ZStack(alignment: alignment.stackAlignment) {
                ComponentsView(componentViewModels: self.viewModel.viewModels)
            }
            .background(viewModel.backgroundColor)
            .padding(viewModel.padding)
        }
    }

}

#endif
