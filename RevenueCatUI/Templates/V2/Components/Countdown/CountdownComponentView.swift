//
//  CountdownComponentView.swift
//  RevenueCat
//
//  Created by Josh Holtz on 11/12/25.
//

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CountdownComponentView: View {

    private let viewModel: CountdownComponentViewModel
    private let onDismiss: () -> Void

    @StateObject private var countdownState: CountdownState

    internal init(
        viewModel: CountdownComponentViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self._countdownState = StateObject(wrappedValue: CountdownState(
            targetDate: viewModel.component.style.date
        ))
    }

    var body: some View {
        Group {
            if let endStackViewModel = viewModel.endStackViewModel, countdownState.hasEnded {
                StackComponentView(
                    viewModel: endStackViewModel,
                    onDismiss: onDismiss
                )
            } else {
                StackComponentView(
                    viewModel: viewModel.countdownStackViewModel,
                    onDismiss: onDismiss
                )
            }
        }
        .environment(\.countdownTime, countdownState.countdownTime)
        .onAppear {
            countdownState.start()
        }
        .onDisappear {
            countdownState.stop()
        }
    }

}

// MARK: - Environment Key

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CountdownTimeKey: EnvironmentKey {
    static let defaultValue: CountdownTime? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var countdownTime: CountdownTime? {
        get { self[CountdownTimeKey.self] }
        set { self[CountdownTimeKey.self] = newValue }
    }
}

#endif
