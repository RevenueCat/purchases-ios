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
                            .accessibilityHidden(true)
                    case .lazy:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .transition(transition.toTransition)
            }
        }.onAppear {
            withAnimation(transition.animation?.toAnimation ?? .none) {
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

extension PaywallComponent.Animation {
    var toAnimation: SwiftUI.Animation {
        switch self.type {
        case .easeIn:
            return .easeIn(duration: msDuration.seconds).delay(msDelay.seconds)
        case .easeInOut:
            return .easeInOut(duration: msDuration.seconds).delay(msDelay.seconds)
        case .easeOut:
            return .easeOut(duration: msDuration.seconds).delay(msDelay.seconds)
        case .linear:
            return .linear(duration: msDuration.seconds).delay(msDelay.seconds)
        @unknown default:
            return .default
        }
    }
}

private extension Int {
    var seconds: TimeInterval {
        return TimeInterval(Double(self) / 1000)
    }
}
