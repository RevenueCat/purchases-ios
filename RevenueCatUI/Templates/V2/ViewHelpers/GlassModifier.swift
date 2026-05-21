//
//  GlassModifier.swift
//  RevenueCat
//
//  Created by Dave DeLong on 5/20/26.
//

import SwiftUI
@_spi(Internal) import RevenueCat

// this availability matches that of UIConfigProvider, etc
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct GlassEffectModifier: ViewModifier {
    
    var effect: PaywallComponent.GlassEffect?
    var shape: PaywallComponent.Shape?
    var uiConfigProvider: UIConfigProvider
    
    @Environment(\.colorScheme) var colorScheme
    
    init(stackViewModel: StackComponentViewModel) {
        self.effect = stackViewModel.component.glassEffect
        self.shape = stackViewModel.component.shape
        self.uiConfigProvider = stackViewModel.uiConfigProvider
    }
    
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, *)
    var resolvedGlassEffect: Glass {
        var glass: Glass
        switch effect?.effect {
            case .none: glass = .identity
            case .clear: glass = .clear
            case .glassy: glass = .regular
        }
        
        if let tint = effect?.tint, let resolved = try? DisplayableColorScheme.from(colorScheme: tint, uiConfigProvider: uiConfigProvider) {
            let color = resolved.toDynamicColor(with: colorScheme)
            glass = glass.tint(color)
        }
        
        if let interactive = effect?.interactive {
            glass = glass.interactive(interactive)
        }
        
        return glass
    }
    
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, *)
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
        if #available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            content
                .glassEffect(resolvedGlassEffect, in: resolvedShape)
        } else {
            content
        }
    }
}
