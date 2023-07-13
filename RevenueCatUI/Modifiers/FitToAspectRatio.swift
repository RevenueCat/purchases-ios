//
//  FitToAspectRatio.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct FitToAspectRatio: ViewModifier {

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

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension Image {

    func fitToAspect(_ aspectRatio: Double, contentMode: SwiftUI.ContentMode) -> some View {
        self.resizable()
            .scaledToFill()
            .modifier(FitToAspectRatio(aspectRatio: aspectRatio, contentMode: contentMode))
    }

}
