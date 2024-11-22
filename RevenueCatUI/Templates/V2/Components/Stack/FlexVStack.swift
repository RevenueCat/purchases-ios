//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FlexVStack.swift
//
//  Created by Josh Holtz on 11/1/24.

import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FlexVStack: View {
    let alignment: HorizontalAlignment
    let justifyContent: JustifyContent
    let spacing: CGFloat?
    let componentViewModels: [PaywallComponentViewModel]

    let onDismiss: () -> Void

    init(
        alignment: HorizontalAlignment,
        spacing: CGFloat?,
        justifyContent: JustifyContent,
        componentViewModels: [PaywallComponentViewModel],
        onDismiss: @escaping () -> Void
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.justifyContent = justifyContent
        self.componentViewModels = componentViewModels
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: self.alignment, spacing: self.spacing) {
            switch justifyContent {
            case .start:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                }
                Spacer(minLength: 0)

            case .center:
                Spacer(minLength: 0)
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                }
                Spacer()

            case .end:
                Spacer(minLength: 0)
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                }

            case .spaceBetween:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                    if index < self.componentViewModels.count - 1 {
                        Spacer(minLength: 0)
                    }
                }

            case .spaceAround:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    Spacer(minLength: 0)
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                    Spacer(minLength: 0)
                }

            case .spaceEvenly:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    Spacer(minLength: 0)
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

#endif
