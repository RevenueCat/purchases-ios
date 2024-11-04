//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FlexHStack.swift
//
//  Created by Josh Holtz on 11/1/24.

import SwiftUI

#if PAYWALL_COMPONENTS

enum JustifyContent {
    case start, center, end, spaceBetween, spaceAround, spaceEvenly
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FlexHStack: View {
    let alignment: VerticalAlignment
    let justifyContent: JustifyContent
    let spacing: CGFloat?
    let componentViewModels: [PaywallComponentViewModel]

    let onDismiss: () -> Void

    init(
        alignment: VerticalAlignment,
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
        HStack(alignment: self.alignment, spacing: self.spacing) {
            switch justifyContent {
            case .start:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                }
                Spacer()

            case .center:
                Spacer()
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                }
                Spacer()

            case .end:
                Spacer()
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                }

            case .spaceBetween:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                    if index < self.componentViewModels.count - 1 {
                        Spacer()
                    }
                }

            case .spaceAround:
                Spacer()
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                    if index < self.componentViewModels.count - 1 {
                        Spacer()
                    }
                }
                Spacer()

            case .spaceEvenly:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    Spacer()
                    ComponentsView(componentViewModels: [self.componentViewModels[index]], onDismiss: self.onDismiss)
                }
                Spacer()
            }
        }
    }
}

#endif
