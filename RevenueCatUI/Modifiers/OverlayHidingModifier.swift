//
//  OverlayHidingModifier.swift
//
//
//  Created by Nacho Soto on 8/9/23.
//

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension View {

    func hideOverlayContent(
        _ configuration: TemplateViewConfiguration,
        hide: Bool,
        offset: CGFloat
    ) -> some View {
        return self.modifier(OverlayHidingModifier(configuration: configuration,
                                                   hide: hide,
                                                   offset: offset))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct OverlayHidingModifier: ViewModifier {

    @State
    private var height: CGFloat = 10

    var configuration: TemplateViewConfiguration
    var hide: Bool
    var offset: CGFloat

    func body(content: Content) -> some View {
        switch self.configuration.mode {
        case .fullScreen, .overlay:
            // These modes don't support hiding the content
            content
                .padding(.vertical)

        case .condensedOverlay:
            // "Hidden view" so it doesn't contribute to size calculation
            Rectangle()
                .frame(height: VersionDetector.iOS15 ? 1 : 0) // Note: height "0" breaks iOS 15
                .hidden()
                .frame(maxWidth: .infinity)
                .overlay(alignment: .bottom) {
                    // Content is displayed as an overlay so it's rendered over user's content
                    content
                        .padding(.vertical)
                        .padding(.bottom, Constants.defaultCornerRadius * 2.0)
                        .background(self.configuration.backgroundView)
                        .onSizeChange(.vertical) { self.height = $0 }
                        .opacity(self.hide ? 0 : 1)
                        .offset(
                            y: self.hide
                            ? self.offset
                            : Constants.defaultCornerRadius * 3.0
                        )
                        .frame(height: self.hide ? 0 : nil)
                        .blur(radius: self.hide ? Self.blurRadius : 0)
                }

        }
    }

    private static let blurRadius: CGFloat = 20

}
