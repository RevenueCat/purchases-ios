//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransitionView.swift
//
//  Created by Jacob Zivan Rakidzich on 8/20/25.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TransitionView<Content: View>: View {
    let transition: PaywallComponent.Transition
    let content: () -> Content

    @State var isPresented: Bool = false

    var body: some View {
        ZStack {
            if isPresented {
                content()
                    .transition(transition.toTransition)
            } else {
                if transition.displacementStrategy == .greedy {
                    content()
                        .hidden()
                        .accessibilityHidden(true)
                        .transition(transition.toTransition)
                } else {
                    EmptyView()
                        .transition(transition.toTransition)
                }
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
            TransitionView(transition: transition) {
                self
            }
        } else {
            self
        }
    }
}

extension PaywallComponent.Transition {
    var toTransition: SwiftUI.AnyTransition {
        switch self.type {
        case .fade:
            .opacity
        case .fadeAndScale:
            .opacity.combined(with: .scale)
        case .scale:
            .scale
        case .slide:
            .slide
        case .custom:
            // WIP: will add this later
            .identity
        @unknown default:
            .identity
        }
    }

}

extension PaywallComponent.Animation {
    var toAnimation: SwiftUI.Animation {
        switch self.type {
        case .bouncy:
            if let duration = msDuration?.seconds {
                return .bouncy(duration: duration).delay(msDelay?.seconds ?? 0)
            }
            return .bouncy.delay(msDelay?.seconds ?? 0)
        case .easeIn:
            if let duration = msDuration?.seconds {
                return .easeIn(duration: duration).delay(msDelay?.seconds ?? 0)
            }
            return .easeIn.delay(msDelay?.seconds ?? 0)
        case .easeInOut:
            if let duration = msDuration?.seconds {
                return .easeInOut(duration: duration).delay(msDelay?.seconds ?? 0)
            }
            return .easeInOut.delay(msDelay?.seconds ?? 0)
        case .easeOut:
            if let duration = msDuration?.seconds {
                return .easeOut(duration: duration).delay(msDelay?.seconds ?? 0)
            }
            return .easeOut.delay(msDelay?.seconds ?? 0)
        case .linear:
            if let duration = msDuration?.seconds {
                return .linear(duration: duration).delay(msDelay?.seconds ?? 0)
            }
            return .linear.delay(msDelay?.seconds ?? 0)
        case .smooth:
            if let duration = msDuration?.seconds {
                return .smooth(duration: duration).delay(msDelay?.seconds ?? 0)
            }
            return .smooth.delay(msDelay?.seconds ?? 0)
        case .snappy:
            if let duration = msDuration?.seconds {
                return .snappy(duration: duration).delay(msDelay?.seconds ?? 0)
            }
            return .snappy.delay(msDelay?.seconds ?? 0)
        case .spring:
            if let duration = msDuration?.seconds {
                return .spring(duration: duration).delay(msDelay?.seconds ?? 0)
            }
            return .spring.delay(msDelay?.seconds ?? 0)
        case .custom:
            // WIP: will add this later
            return .default
        @unknown default:
                return .default
        }
    }
}

private extension Int {
    var seconds: TimeInterval {
        TimeInterval(Double(self) / 1000)
    }
}
