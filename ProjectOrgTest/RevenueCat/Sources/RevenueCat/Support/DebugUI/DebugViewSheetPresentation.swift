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

#if DEBUG && swift(>=5.8) && (os(iOS) || os(macOS) || VISION_OS)

import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
extension View {

    @ViewBuilder
    func bottomSheet(
        presentationDetents: Set<PresentationDetent>,
        isPresented: Binding<Bool>,
        largestUndimmedIdentifier: PresentationDetent = .large,
        cornerRadius: CGFloat,
        interactiveDismissDisabled: Bool = false,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        self
            .sheet(isPresented: isPresented) {
                let result = content()
                    .presentationDetents(presentationDetents)
                    .presentationDragIndicator(.automatic)
                    .interactiveDismissDisabled(interactiveDismissDisabled)

                if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
                    result
                        .presentationCornerRadius(cornerRadius)
                        .presentationBackgroundInteraction(.enabled(upThrough: largestUndimmedIdentifier))
                } else {
                    result
                }
            }
    }
}

#endif
