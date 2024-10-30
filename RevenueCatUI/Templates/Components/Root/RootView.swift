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

#if PAYWALL_COMPONENTS

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
        ScrollView {
            StackComponentView(viewModel: viewModel.stackViewModel, onDismiss: onDismiss)
        }.applyIfLet(viewModel.stickyFooterViewModel) { stackView, stickyFooterViewModel in
            stackView
                .safeAreaInset(edge: .bottom) {
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
                }
                // First we ensure our footer draws in the bottom safe area. Then we add additional padding, so its
                // background shows in that same bottom safe area.
                .ignoresSafeArea(edges: .bottom)
                .onBottomSafeAreaPaddingChange { bottomPadding in
                    self.additionalFooterPaddingBottom = bottomPadding
                }

        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OnBottomSafeAreaPaddingChangeModifier: ViewModifier {
    private let callback: (CGFloat) -> Void

    init(_ callback: @escaping (CGFloat) -> Void) {
        self.callback = callback
    }

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            callback(geometry.safeAreaInsets.bottom)
                        }
                        .onChange(of: geometry.safeAreaInsets.bottom) { newValue in
                            callback(newValue)
                        }
                }
            )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension View {
    /// Sort-of backported safeAreaPadding (iOS 17+), for as much as we need.
    func onBottomSafeAreaPaddingChange(_ callback: @escaping (CGFloat) -> Void) -> some View {
        self.modifier(OnBottomSafeAreaPaddingChangeModifier(callback))
    }
}

#endif
