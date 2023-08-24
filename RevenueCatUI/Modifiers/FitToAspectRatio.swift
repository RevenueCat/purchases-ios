//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FitToAspectRatio.swift
//
//  Created by Nacho Soto on 7/13/23.

import Foundation
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension Image {

    func fitToAspect(_ aspectRatio: Double, contentMode: SwiftUI.ContentMode) -> some View {
        self.resizable()
            .scaledToFill()
            .modifier(FitToAspectRatio(aspectRatio: aspectRatio, contentMode: contentMode))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct FitToAspectRatio: ViewModifier {

    let aspectRatio: Double
    let contentMode: SwiftUI.ContentMode

    func body(content: Content) -> some View {
        Color.clear
            .aspectRatio(self.aspectRatio, contentMode: .fit)
            .overlay(
                content.aspectRatio(nil, contentMode: self.contentMode)
            )
    }

}
