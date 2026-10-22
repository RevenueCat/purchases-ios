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

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FlexVStack: View {
    @Environment(\.nativePaywallHiddenLayoutButtons) private var hiddenNativeButtons
    @Environment(\.nativePaywallInvisibleLayoutButtons) private var invisibleButtons

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

    private var visibleIndices: [Int] {
        self.componentViewModels.indicesExcludingNativeButtons(
            self.hiddenNativeButtons, invisibleButtons: self.invisibleButtons
        )
    }

    var body: some View {
        VStack(alignment: self.alignment, spacing: 0) {
            switch justifyContent {
            case .start:
                ForEach(self.visibleIndices, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index != self.visibleIndices.last {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                    }
                }
                Spacer(minLength: 0)

            case .center:
                Spacer(minLength: 0)
                ForEach(self.visibleIndices, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index != self.visibleIndices.last {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                    }
                }
                Spacer(minLength: 0)

            case .end:
                Spacer(minLength: 0)
                ForEach(self.visibleIndices, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index != self.visibleIndices.last {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                    }
                }

            case .spaceBetween:
                ForEach(self.visibleIndices, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index != self.visibleIndices.last {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                        Spacer(minLength: 0)
                    }
                }

            case .spaceAround:
                ForEach(self.visibleIndices, id: \.self) { index in
                    if index == self.visibleIndices.first {
                        FlexSpacer(weight: 1)
                    }
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index != self.visibleIndices.last {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                        FlexSpacer(weight: 2)
                    } else {
                        FlexSpacer(weight: 1)
                    }
                }

            case .spaceEvenly:
                ForEach(self.visibleIndices, id: \.self) { index in
                    FlexSpacer(weight: 1)
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index != self.visibleIndices.last {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
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
