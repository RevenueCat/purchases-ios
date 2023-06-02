//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DebugViewSheetPresentation.swift
//
//  Created by Nacho Soto on 5/30/23.

#if DEBUG && os(iOS)

import SwiftUI

@available(iOS 16.0, *)
extension View {

    @ViewBuilder
    func bottomSheet(
        presentationDetents: Set<PresentationDetent>,
        isPresented: Binding<Bool>,
        largestUndimmedIdentifier: UISheetPresentationController.Detent.Identifier = .large,
        cornerRadius: CGFloat,
        transparentBackground: Bool = false,
        interactiveDismissDisabled: Bool = false,
        @ViewBuilder content: @escaping () -> some View,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self
            .sheet(isPresented: isPresented) {
                onDismiss?()
            } content: {
                content()
                    .presentationDetents(presentationDetents)
                    .presentationDragIndicator(.automatic)
                    .interactiveDismissDisabled(interactiveDismissDisabled)
                    .onAppear {
                        guard let scene = SystemInfo.sharedUIApplication?.connectedScenes.first as? UIWindowScene,
                              let rootController = scene.windows.first?.rootViewController,
                              let presentedController = rootController.presentedViewController,
                              let sheet = presentedController.presentationController
                                as? UISheetPresentationController else {
                            Logger.appleWarning("Sheet not found, unable to configure")
                            return
                        }

                        // These are only available on `UISheetPresentationController` but not SwiftUI
                        sheet.largestUndimmedDetentIdentifier = largestUndimmedIdentifier
                        sheet.preferredCornerRadius = cornerRadius

                        // UIKit workaround: avoid tint breaking after dismissing
                        presentedController.presentingViewController?.view.tintAdjustmentMode = .normal

                        if transparentBackground {
                            presentedController.view.backgroundColor = .clear
                        }
                    }
            }
    }
}

#endif
