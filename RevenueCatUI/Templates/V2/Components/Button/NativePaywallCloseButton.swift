//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import SwiftUI

#if !os(tvOS)

/// Replaces only opted-in close buttons. Other platforms and missing/hidden navigation bars
/// retain the configured component; this never creates a navigation container.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallCloseButton<Content: View>: View {
    let enabled: Bool
    let accessibilityLabel: String
    let action: () async throws -> Void
    @ViewBuilder var content: () -> Content
    var availabilityChanged: ((Bool) -> Void)?
    @State private var hasUIKitClose = false
    @State private var hasToolbarClose = false
    @State private var hasNavigation = false

    private var hasNativeClose: Bool { self.hasUIKitClose || self.hasToolbarClose }

    var body: some View {
        #if os(iOS)
        if self.enabled {
            Group {
                if self.hasNativeClose {
                    Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
                } else {
                    self.content()
                }
            }
            .applyIf(self.hasNavigation) { view in
                view.toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        self.toolbarClose
                            .background {
                                NativeToolbarVisibilityObserver { self.hasToolbarClose = $0 }
                                    .frame(width: 0, height: 0)
                            }
                    }
                }
            }
            .background {
                NativePaywallCloseBridge(
                    accessibilityLabel: self.accessibilityLabel,
                    installUIKitClose: !self.hasToolbarClose,
                    action: { Task { try await self.action() } },
                    navigationChanged: { self.hasNavigation = $0 },
                    availabilityChanged: { self.hasUIKitClose = $0 }
                )
                .frame(width: 0, height: 0)
            }
            .onChange(of: self.hasNativeClose) { self.availabilityChanged?($0) }
        } else {
            self.content()
        }
        #else
        self.content()
        #endif
    }
    #if os(iOS)
    @ViewBuilder private var toolbarClose: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Button(role: .close) { Task { try await self.action() } }
                .accessibilityLabel(self.accessibilityLabel)
        } else {
            self.legacyToolbarClose
        }
        #else
        self.legacyToolbarClose
        #endif
    }

    private var legacyToolbarClose: some View {
        Button(action: { Task { try await self.action() } }, label: {
            Image(systemName: "xmark")
        })
        .accessibilityLabel(self.accessibilityLabel)
    }
    #endif

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallCloseEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
extension EnvironmentValues {
    var nativePaywallCloseEnabled: Bool {
        get { self[NativePaywallCloseEnabledKey.self] }
        set { self[NativePaywallCloseEnabledKey.self] = newValue }
    }
}

#endif
