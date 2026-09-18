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

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FlexHStack: View {

    let alignment: VerticalAlignment
    let justifyContent: JustifyContent
    let spacing: CGFloat?
    let children: [IdentifiedPaywallComponentViewModel]
    let onDismiss: () -> Void

    init(
        alignment: VerticalAlignment,
        spacing: CGFloat?,
        justifyContent: JustifyContent,
        children: [IdentifiedPaywallComponentViewModel],
        onDismiss: @escaping () -> Void
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.justifyContent = justifyContent
        self.children = children
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(alignment: self.alignment, spacing: 0) {
            switch justifyContent {
            case .start:
                ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                    ComponentsView(
                        components: [child],
                        onDismiss: self.onDismiss
                    )
                    if index < self.children.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                    }
                }
                Spacer(minLength: 0)

            case .center:
                Spacer(minLength: 0)
                ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                    ComponentsView(
                        components: [child],
                        onDismiss: self.onDismiss
                    )
                    if index < self.children.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                    }
                }
                Spacer(minLength: 0)

            case .end:
                Spacer(minLength: 0)
                ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                    ComponentsView(
                        components: [child],
                        onDismiss: self.onDismiss
                    )
                    if index < self.children.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                    }
                }

            case .spaceBetween:
                ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                    ComponentsView(
                        components: [child],
                        onDismiss: self.onDismiss
                    )
                    if index < self.children.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                        Spacer(minLength: 0)
                    }
                }

            case .spaceAround:
                ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                    if index == 0 {
                        FlexSpacer(weight: 1)
                    }
                    ComponentsView(
                        components: [child],
                        onDismiss: self.onDismiss
                    )
                    if index < self.children.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                        FlexSpacer(weight: 2)
                    } else {
                        FlexSpacer(weight: 1)
                    }
                }

            case .spaceEvenly:
                ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                    FlexSpacer(weight: 1)
                    ComponentsView(
                        components: [child],
                        onDismiss: self.onDismiss
                    )
                    if index < self.children.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(width: spacing)
                        }
                    } else {
                        FlexSpacer(weight: 1)
                    }
                }
            }
        }
    }
}

#endif
