//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NavigationBarModifier.swift
//
//  Created by Josh Holtz on 2/9/25.


import Foundation
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct NavigationBarModifier: ViewModifier {

    let viewModel: NavigationBarComponentViewModel?
    let onDismiss: () -> Void

    var needsToolbar: Bool {
        return self.viewModel?.leadingStackViewModel != nil || self.viewModel?.trailingStackViewModel != nil
    }

    func body(content: Content) -> some View {
        if needsToolbar {
            NavigationViewIfNeeded {
                content
                    .applyIfLet(self.viewModel?.leadingStackViewModel) { view, stack in
                        view.toolbar(content: {
                            ToolbarItem(placement: .topBarLeading) {
                                ComponentsView(
                                    componentViewModels: [.stack(stack)],
                                    onDismiss: self.onDismiss
                                )
                            }
                        })
                    }
                    .applyIfLet(self.viewModel?.trailingStackViewModel) { view, stack in
                        view.toolbar(content: {
                            ToolbarItem(placement: .topBarTrailing) {
                                ComponentsView(
                                    componentViewModels: [.stack(stack)],
                                    onDismiss: self.onDismiss
                                )
                            }
                        })
                    }
            }
        } else {
            content
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func navigationBar(_ viewModel: NavigationBarComponentViewModel?, onDismiss: @escaping () -> Void) -> some View {
        self.modifier(NavigationBarModifier(
            viewModel: viewModel,
            onDismiss: onDismiss
        ))
    }
}

#endif
