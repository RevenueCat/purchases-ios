//
//  FooterHidingModifier.swift
//
//
//  Created by Nacho Soto on 8/9/23.
//

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension View {

    func hideFooterContent(
        _ configuration: TemplateViewConfiguration,
        hide: Bool
    ) -> some View {
        return self.modifier(FooterHidingModifier(configuration: configuration,
                                                hide: hide))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct FooterHidingModifier: ViewModifier {

    @State
    private var height: CGFloat = 10

    var configuration: TemplateViewConfiguration
    var hide: Bool

    func body(content: Content) -> some View {
        switch self.configuration.mode {
        case .fullScreen, .footer:
            // These modes don't support hiding the content
            content
                .padding(.vertical)

        case .condensedFooter:
            content
                .onSizeChange(.vertical) { self.height = $0 }
                .opacity(self.hide ? 0 : 1)
                .frame(height: self.hide ? 0 : nil, alignment: .top)
                .clipped()
                .transition(.move(edge: .bottom))

        }
    }

    private static let blurRadius: CGFloat = 20

}
