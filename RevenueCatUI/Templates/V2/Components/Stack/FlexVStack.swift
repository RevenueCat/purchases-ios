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

private struct FlexVStackContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FlexVStack: View {
    let alignment: HorizontalAlignment
    let justifyContent: JustifyContent
    let spacing: CGFloat?
    let fitMinimum: CGFloat?
    let componentViewModels: [PaywallComponentViewModel]
    let onDismiss: () -> Void

    @State
    private var contentHeight: CGFloat?

    init(
        alignment: HorizontalAlignment,
        spacing: CGFloat?,
        justifyContent: JustifyContent,
        fitMinimum: CGFloat? = nil,
        componentViewModels: [PaywallComponentViewModel],
        onDismiss: @escaping () -> Void
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.justifyContent = justifyContent
        self.fitMinimum = fitMinimum
        self.componentViewModels = componentViewModels
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: self.alignment, spacing: 0) {
            switch justifyContent {
            case .start:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                    }
                }
                Spacer(minLength: 0)

            case .center:
                Spacer(minLength: 0)
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                    }
                }
                Spacer(minLength: 0)

            case .end:
                Spacer(minLength: 0)
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    ComponentsView(
                        componentViewModels: [self.componentViewModels[index]],
                        onDismiss: self.onDismiss
                    )
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                    }
                }

            case .spaceBetween:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    self.component(at: index)
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                        FlexSpacer(
                            weight: 1,
                            axis: .vertical,
                            lengthPerWeight: self.fixedSpaceLength(
                                totalWeight: self.componentViewModels.count - 1
                            )
                        )
                    }
                }

            case .spaceAround:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    if index == 0 {
                        self.spaceAroundSpacer(weight: 1)
                    }
                    self.component(at: index)
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                        self.spaceAroundSpacer(weight: 2)
                    } else {
                        self.spaceAroundSpacer(weight: 1)
                    }
                }

            case .spaceEvenly:
                ForEach(0..<componentViewModels.count, id: \.self) { index in
                    self.spaceEvenlySpacer()
                    self.component(at: index)
                    if index < self.componentViewModels.count - 1 {
                        if let spacing = self.spacing {
                            Spacer().frame(height: spacing)
                        }
                    } else {
                        self.spaceEvenlySpacer()
                    }
                }
            }
        }
        .onPreferenceChange(FlexVStackContentHeightPreferenceKey.self) {
            if self.fitMinimum != nil, self.contentHeight != $0 {
                self.contentHeight = $0
            }
        }
    }

    private func component(at index: Int) -> some View {
        ComponentsView(
            componentViewModels: [self.componentViewModels[index]],
            onDismiss: self.onDismiss
        )
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: FlexVStackContentHeightPreferenceKey.self,
                    value: proxy.size.height
                )
            }
        )
    }

    private func spaceAroundSpacer(weight: Int) -> some View {
        FlexSpacer(
            weight: weight,
            axis: .vertical,
            lengthPerWeight: self.fixedSpaceLength(totalWeight: self.componentViewModels.count * 2)
        )
    }

    private func spaceEvenlySpacer() -> some View {
        FlexSpacer(
            weight: 1,
            axis: .vertical,
            lengthPerWeight: self.fixedSpaceLength(totalWeight: self.componentViewModels.count + 1)
        )
    }

    private func fixedSpaceLength(totalWeight: Int) -> CGFloat? {
        guard self.fitMinimum != nil else {
            return nil
        }
        guard let contentHeight = self.contentHeight else {
            return 0
        }

        return FlexSpacer.lengthPerWeight(
            fitMinimum: self.fitMinimum,
            contentLength: contentHeight,
            spacing: self.spacing,
            componentCount: self.componentViewModels.count,
            totalWeight: totalWeight
        )
    }
}

#endif
