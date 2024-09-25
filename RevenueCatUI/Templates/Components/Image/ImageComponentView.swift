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
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ImageComponentView: View {

    @Environment(\.selectionState) var selectionState

    let viewModel: ImageComponentViewModel

    var body: some View {
        RemoteImage(url: viewModel.url(for: selectionState)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: viewModel.contentMode(for: selectionState))
                .frame(maxHeight: viewModel.maxHeight(for: selectionState))
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: viewModel.gradientColors(for: selectionState)),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(viewModel.cornerRadius(for: selectionState))
        }
        .clipped()
    }

}

#endif
