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
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return color }
        return  UIColor(
            red: max(red - amount, 0),
            green: max(green - amount, 0),
            blue: max(blue - amount, 0),
            alpha: alpha
        )
    }
}
