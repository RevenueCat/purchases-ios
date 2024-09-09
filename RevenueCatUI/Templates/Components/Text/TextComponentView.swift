//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TextComponentView: View {

    let viewModel: TextComponentViewModel

    var body: some View {
        Text(viewModel.text)
            .font(viewModel.textStyle)
            .fontWeight(viewModel.fontWeight)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(viewModel.horizontalAlignment)
            .foregroundStyle(viewModel.color)
            .padding(viewModel.padding)
            .background(viewModel.backgroundColor)
            .padding(viewModel.margin)
    }

}

#endif
