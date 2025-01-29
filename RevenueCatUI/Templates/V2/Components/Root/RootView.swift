//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootView.swift
//
//  Created by Jay Shortway on 24/10/2024.

import Foundation
import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RootView: View {
    @State private var additionalFooterPaddingBottom: CGFloat = 0

    private let viewModel: RootViewModel
    private let onDismiss: () -> Void

    internal init(viewModel: RootViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ScrollView {
                StackComponentView(viewModel: viewModel.stackViewModel, onDismiss: onDismiss)
            }

            if let stickyFooterViewModel = viewModel.stickyFooterViewModel {
                StackComponentView(
                    viewModel: stickyFooterViewModel.stackViewModel,
                    onDismiss: onDismiss,
                    additionalPadding: EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: additionalFooterPaddingBottom,
                        trailing: 0
                    )
                )
                .fixedSize(horizontal: false, vertical: true)

                // This spacer is to prevent the bottom most view from expanding into the
                // safe space. iOS will take the bottom view and expand it to fill the
                // the safe space and we don't want anything there.
                Spacer()
            }
        }
    }

}

#endif
