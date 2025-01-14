//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompatibilityNavigationStack.swift
//
//
//  Created by Cody Kerns on 8/15/24.
//

#if os(iOS)

import SwiftUI

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CompatibilityNavigationStack<Content: View>: View {

    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
        }
    }

}

extension View {
    /// Adds backward-compatible navigation, supporting both iOS 16+ and earlier versions.
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean that determines whether the destination is presented.
    ///   - destination: A closure that returns the destination view.
    func compatibleNavigation<Destination: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        Group {
            if #available(iOS 16.0, *) {
                self.navigationDestination(isPresented: isPresented) {
                    destination()
                }
            } else {
                self.background(
                    NavigationLink(
                        destination: destination(),
                        isActive: isPresented
                    ) {
                        EmptyView()
                    }
                )
            }
        }
    }
}

extension View {
    /// Adds backward-compatible navigation, supporting both iOS 16+ and earlier versions, triggered by an optional binding.
    /// - Parameters:
    ///   - item: A binding to an optional value that triggers navigation when non-nil.
    ///   - destination: A closure that returns the destination view, taking the unwrapped value as a parameter.
    func compatibleNavigation<Item, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        Group {
            if #available(iOS 16.0, *) {
                self.navigationDestination(
                    isPresented: Binding<Bool>(
                        get: { item.wrappedValue != nil },
                        set: { isActive in
                            if !isActive {
                                item.wrappedValue = nil
                            }
                        }
                    )
                ) {
                    if let unwrappedItem = item.wrappedValue {
                        destination(unwrappedItem)
                    }
                }
            } else {
                self.background(
                    NavigationLink(
                        destination: item.wrappedValue.map { destination($0) },
                        isActive: Binding<Bool>(
                            get: { item.wrappedValue != nil },
                            set: { isActive in
                                if !isActive {
                                    item.wrappedValue = nil
                                }
                            }
                        )
                    ) {
                        EmptyView()
                    }
                )
            }
        }
    }
}

#endif
