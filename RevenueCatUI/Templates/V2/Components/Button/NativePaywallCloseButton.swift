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
/// retain the configured component until native placement is available.
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
            VStack(spacing: 0) {
                if self.hasNativeClose {
                    Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
                } else {
                    self.content()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if self.hasNavigation {
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
            .preference(key: NativePaywallCloseRequestedKey.self, value: true)
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

/// Wraps the whole paywall, rather than an individual component, only when an eligible close
/// button requests native placement and the caller has not supplied a navigation container.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
struct NativePaywallNavigationModifier: ViewModifier {
    #if os(iOS)
    @State private var requested = false
    @State private var hasNavigation: Bool?
    @State private var addsNavigation = false

    func body(content: Content) -> some View {
        Group {
            if self.addsNavigation {
                if #available(iOS 16.0, *) {
                    NavigationStack { content.toolbar(.visible, for: .navigationBar) }
                } else {
                    NavigationView { content.navigationBarHidden(false) }.navigationViewStyle(.stack)
                }
            } else {
                content
            }
        }
        .onPreferenceChange(NativePaywallCloseRequestedKey.self) { requested in
            self.requested = requested
            self.wrapIfNeeded()
        }
        .background {
            NativePaywallNavigationObserver { hasNavigation in
                self.hasNavigation = hasNavigation
                self.wrapIfNeeded()
            }
            .frame(width: 0, height: 0)
        }
    }

    private func wrapIfNeeded() {
        // Keep the wrapper for this presentation once installed. Rebuilding the content can
        // temporarily clear preferences, which must not repeatedly remove and recreate its stack.
        if self.requested && self.hasNavigation == false { self.addsNavigation = true }
    }
    #else
    func body(content: Content) -> some View { content }
    #endif
}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
private struct NativePaywallCloseRequestedKey: PreferenceKey {
    static var defaultValue: Bool { false }

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

#if os(iOS)
@available(iOS 15.0, *)
private struct NativePaywallNavigationObserver: UIViewControllerRepresentable {
    let changed: (Bool) -> Void

    func makeUIViewController(context: Context) -> NativePaywallCloseBridge.NavigationObserver {
        NativePaywallCloseBridge.NavigationObserver()
    }

    func updateUIViewController(_ controller: NativePaywallCloseBridge.NavigationObserver, context: Context) {
        controller.changed = { [weak controller] in
            guard let controller, controller.viewIfLoaded?.window != nil else { return }
            self.changed(controller.navigationController != nil)
        }
        controller.scheduleUpdate()
    }

    static func dismantleUIViewController(
        _ controller: NativePaywallCloseBridge.NavigationObserver, coordinator: ()
    ) {
        controller.changed = nil
    }
}
#endif

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
