//
//  DefaultTemplateBackgroundColorView.swift
//  RevenueCat
//
//  Created by Andrés Boedo on 5/5/25.
//
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 10.0, *)
struct DefaultTemplateBackgroundColorView: View {
    private let backgroundColorOpacity = 0.4
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(darkened(color: UIColor.tintColor, amount: 0.3))
                        .opacity(backgroundColorOpacity),
                    Color(UIColor.tintColor)
                        .opacity(backgroundColorOpacity),
                    Color(UIColor.tintColor)
                        .opacity(0.7),
                    Color(darkened(color: UIColor.tintColor, amount: 0.5))
                        .opacity(backgroundColorOpacity),
                    Color(darkened(color: UIColor.tintColor, amount: 0.1))
                        .opacity(backgroundColorOpacity),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
    
    private func darkened(color: UIColor, amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return color }
        let color =  UIColor(
            red: max(r - amount, 0),
            green: max(g - amount, 0),
            blue: max(b - amount, 0),
            alpha: a
        )
        print(color)
        return color
    }
}
