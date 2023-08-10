//
//  CardHidingModifier.swift
//
//
//  Created by Nacho Soto on 8/9/23.
//

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension View {

    func hideCardContent(_ hide: Bool, _ offset: CGFloat) -> some View {
        return self.modifier(CardHidingModifier(hide: hide, offset: offset))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct CardHidingModifier: ViewModifier {

    var hide: Bool
    var offset: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(self.hide ? 0 : 1)
            .offset(y: self.hide ? self.offset : 0)
            .frame(height: self.hide ? 0 : nil)
            .blur(radius: self.hide ? Self.blurRadius : 0)
    }

    private static let blurRadius: CGFloat = 20

}
