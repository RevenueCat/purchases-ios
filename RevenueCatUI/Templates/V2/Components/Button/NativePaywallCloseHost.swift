//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS)

@MainActor
private func performNativePaywallAction(_ action: () async throws -> Void) async {
    do {
        try await action()
    } catch {
        Logger.error(Strings.paywall_native_navigation_action_failed(error))
    }
}

/// A single host renders native Back and Close. Components contribute their existing actions only.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallCloseHost: ViewModifier {
    static let closeIdentifier = "RevenueCat.NativePaywallClose"
    static let backIdentifier = "RevenueCat.NativePaywallBack"
    var enabled = true
    @StateObject private var coordinator = NativePaywallCloseCoordinator()

    @ViewBuilder func body(content: Content) -> some View {
        #if os(iOS)
            self.surface(content)
                .navigationBarBackButtonHidden(self.coordinator.action(for: .back) != nil)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        NativePaywallToolbarClose(coordinator: self.coordinator, primary: true)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NativePaywallToolbarClose(coordinator: self.coordinator, primary: false)
                    }
                }
        #else
        content
        #endif
    }

    private func surface(_ content: Content) -> some View {
        VStack(spacing: 0) { content }
            .environment(\.nativePaywallCloseCoordinator, self.enabled ? self.coordinator : nil)
    }

}

#if os(iOS)
@available(iOS 15.0, *)
private struct NativePaywallToolbarClose: View {
    @ObservedObject var coordinator: NativePaywallCloseCoordinator
    let primary: Bool

    @ViewBuilder var body: some View {
        if self.primary {
            if let back = self.coordinator.action(for: .back) {
                Button {
                    Task { await performNativePaywallAction { try await self.coordinator.performAction(id: back.id) } }
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .accessibilityLabel(back.label)
                .accessibilityIdentifier(NativePaywallCloseHost.backIdentifier)
                .disabled(!back.isEnabled)
            }
        } else if let close = self.coordinator.action(for: .close) {
            self.closeButton(close).disabled(!close.isEnabled)
        }
    }

    @ViewBuilder private func closeButton(_ action: NativePaywallCloseCoordinator.CloseAction) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Button(role: .close) {
                Task { await performNativePaywallAction { try await self.coordinator.performAction(id: action.id) } }
            }
                .accessibilityLabel(action.label)
                .accessibilityIdentifier(NativePaywallCloseHost.closeIdentifier)
        } else {
            self.legacyCloseButton(action)
        }
        #else
        self.legacyCloseButton(action)
        #endif
    }

    private func legacyCloseButton(_ action: NativePaywallCloseCoordinator.CloseAction) -> some View {
        Button {
            Task { await performNativePaywallAction { try await self.coordinator.performAction(id: action.id) } }
        } label: { Image(systemName: "xmark") }
            .accessibilityLabel(action.label)
            .accessibilityIdentifier(NativePaywallCloseHost.closeIdentifier)
    }
}
#endif

#endif
