//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransitionModifier.swift
//
//  Created by Jacob Zivan Rakidzich on 8/20/25.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TransitionModifier: ViewModifier {
    let transition: PaywallComponent.Transition

    @State var isPresented: Bool = false

    /// The animation to use without the delay (delay is handled separately)
    private var animationWithoutDelay: SwiftUI.Animation {
        guard let animation = transition.animation else {
            return .default
        }
        switch animation.type {
        case .easeIn:
            return .easeIn(duration: animation.msDuration.asSeconds)
        case .easeInOut:
            return .easeInOut(duration: animation.msDuration.asSeconds)
        case .easeOut:
            return .easeOut(duration: animation.msDuration.asSeconds)
        case .linear:
            return .linear(duration: animation.msDuration.asSeconds)
        @unknown default:
            return .default
        }
    }

    func body(content: Content) -> some View {
        ZStack {
            if isPresented {
                content
                    .transition(transition.toTransition)
            } else {
                Group {
                    switch transition.displacementStrategy {
                    case .greedy:
                        content
                            .hidden()
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    case .lazy:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .transition(transition.toTransition)
            }
        }.task {
            // Delay the state change by msDelay before showing the content
            let delayMs = transition.animation?.msDelay ?? 0
            if delayMs > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
            }
            withAnimation(animationWithoutDelay) {
                isPresented = true
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    @ViewBuilder
    func withTransition(_ transition: PaywallComponent.Transition?) -> some View {
        if let transition {
            self.modifier(TransitionModifier(transition: transition))
        } else {
            self
        }
    }
}

extension PaywallComponent.Transition {
    var toTransition: SwiftUI.AnyTransition {
        switch self.type {
        case .fade:
            return AnyTransition.opacity
        case .fadeAndScale:
            return AnyTransition.opacity.combined(with: .scale)
        case .scale:
            return AnyTransition.scale
        case .slide:
            return AnyTransition.slide
        @unknown default:
            return AnyTransition.identity
        }
    }

}

private extension Int {
    var asSeconds: TimeInterval {
        return TimeInterval(Double(self) / 1000)
    }
}
