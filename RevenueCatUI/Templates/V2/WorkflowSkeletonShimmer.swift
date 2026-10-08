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
extension View {

    @ViewBuilder
    func workflowSkeletonShimmer() -> some View {
        self.modifier(WorkflowSkeletonShimmer())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowSkeletonShimmer: ViewModifier {

    @Environment(\.workflowSkeletonShimmerEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if self.isEnabled && !self.reduceMotion {
            content
                .environment(\.workflowSkeletonShimmerEnabled, false)
                .overlay {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.04), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width)
                        .offset(x: self.isAnimating ? proxy.size.width : -proxy.size.width)
                        .animation(.linear(duration: 2.4).repeatForever(autoreverses: false), value: self.isAnimating)
                        .onAppear { self.isAnimating = true }
                    }
                    .clipped()
                    .blendMode(.sourceAtop)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
                // Isolate the blend so the shimmer only affects this component's visible pixels.
                .compositingGroup()
        } else {
            content
        }
    }

    fileprivate struct EnabledKey: EnvironmentKey {

        static let defaultValue = false

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var workflowSkeletonShimmerEnabled: Bool {
        get { self[WorkflowSkeletonShimmer.EnabledKey.self] }
        set { self[WorkflowSkeletonShimmer.EnabledKey.self] = newValue }
    }

}

#endif
