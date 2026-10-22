//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HeaderComponentView.swift
//
//  Created by Facundo Menzella on 02/04/2026.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct HeaderComponentView: View {

    @Environment(\.safeAreaInsets)
    private var safeAreaInsets

    @Environment(\.workflowRenderingContext)
    private var workflowRenderingContext

    @State private var contentVisibility = NativePaywallHeaderContentKey.defaultValue

    private let viewModel: HeaderComponentViewModel
    private let onDismiss: () -> Void

    init(
        viewModel: HeaderComponentViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        StackComponentView(
            viewModel: self.viewModel.stackViewModel,
            onDismiss: self.onDismiss,
            additionalPadding: .init(
                top: self.viewModel.firstItemIgnoresSafeArea ? 0 : self.safeAreaInsets.top,
                leading: 0,
                bottom: 0,
                trailing: 0
            ),
            isHeaderContainer: true
        )
        .environment(\.workflowRenderingContext, self.workflowRenderingContext.markingHeader())
        .environment(\.nativePaywallHeaderCollapsed, self.collapsesNativeOnlyHeader)
        .onPreferenceChange(NativePaywallHeaderContentKey.self) { self.contentVisibility = $0 }
        // The paywall extends through the top safe area when it has a header. Removing native-only
        // header content must retain the inset that keeps the body below the caller's navigation bar.
        .fixedSize(horizontal: false, vertical: self.collapsesNativeOnlyHeader)
        .frame(height: self.collapsesNativeOnlyHeader ? self.safeAreaInsets.top : nil, alignment: .bottom)
        .opacity(self.collapsesNativeOnlyHeader ? 0 : 1)
        .allowsHitTesting(!self.collapsesNativeOnlyHeader)
        .accessibilityHidden(self.collapsesNativeOnlyHeader)
        .preference(key: NativePaywallCollapsedHeaderKey.self, value: self.collapsesNativeOnlyHeader)
    }

    private var collapsesNativeOnlyHeader: Bool {
        self.contentVisibility.hasNativeButtons && !self.contentVisibility.hasVisibleContent
    }

}

#endif
