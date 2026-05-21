//
//  GlassModifier.swift
//  RevenueCat
//
//  Created by Dave DeLong on 5/20/26.
//

@_spi(Internal) import RevenueCat
import SwiftUI

extension View {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func withGlassEffect(from stackViewModel: StackComponentViewModel) -> some View {
        modifier(GlassEffectModifier(effect: stackViewModel.component.glassEffect,
                                     shape: stackViewModel.component.shape,
                                     uiConfigProvider: stackViewModel.uiConfigProvider))
    }

}

// this availability matches that of UIConfigProvider, etc
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct GlassEffectModifier: ViewModifier {

    var effect: PaywallComponent.GlassEffect?
    var shape: PaywallComponent.Shape?
    var uiConfigProvider: UIConfigProvider

    @Environment(\.colorScheme) var colorScheme

    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    var resolvedGlassEffect: Glass {
        var glass: Glass
        switch effect?.effect {
        case .none: glass = .identity
        case .clear: glass = .clear
        case .glassy: glass = .regular
        }

        if effect != nil {
            if let tint = effect?.tint,
                let resolved = try? DisplayableColorScheme.from(colorScheme: tint, uiConfigProvider: uiConfigProvider) {
                let color = resolved.toDynamicColor(with: colorScheme)
                glass = glass.tint(color)
            }

            if let interactive = effect?.interactive {
                glass = glass.interactive(interactive)
            }
        }

        return glass
    }

    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    var resolvedShape: AnyShape {
        switch shape {
        case .none:
            return AnyShape(.rect)
        case .pill:
            return AnyShape(.capsule)
        case .rectangle(let radii):
            if let radii {
                let uneven = UnevenRoundedRectangle(topLeadingRadius: radii.topLeading ?? 0,
                                                    bottomLeadingRadius: radii.bottomLeading ?? 0,
                                                    bottomTrailingRadius: radii.bottomTrailing ?? 0,
                                                    topTrailingRadius: radii.topTrailing ?? 0)

                return AnyShape(uneven)
            } else {
                return AnyShape(.rect)
            }
        }
    }

    func body(content: Content) -> some View {
        if #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *) {
            content
                .glassEffect(resolvedGlassEffect, in: resolvedShape)
        } else {
            content
        }
    }
}
