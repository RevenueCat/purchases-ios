//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowSkeletonShimmer.swift

import SwiftUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowSkeletonShimmer: ViewModifier {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content.overlay {
            if !self.reduceMotion {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.12), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width)
                    .offset(x: self.isAnimating ? proxy.size.width : -proxy.size.width)
                    .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: self.isAnimating)
                    .onAppear { self.isAnimating = true }
                }
                .clipped()
                .allowsHitTesting(false)
            }
        }
    }

}

#endif
