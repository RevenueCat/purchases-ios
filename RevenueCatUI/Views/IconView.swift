//
//  IconView.swift
//  
//
//  Created by Nacho Soto on 7/25/23.
//

import SwiftUI

/// A view that renders an icon by name, tinted with a color.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct IconView<S: ShapeStyle>: View {

    let icon: PaywallIcon
    let tint: S

    var body: some View {
        Image(self.icon.rawValue, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(self.tint)
    }

}

/// An icon to be displayed by `IconView`.
enum PaywallIcon: String {

    case lock

}

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct IconView_Previews: PreviewProvider {

    static var previews: some View {
        Self.icon(.lock, .green.gradient.shadow(.inner(color: .black, radius: 2)))
    }

    private static func icon<S: ShapeStyle>(_ icon: PaywallIcon, _ color: S) -> some View {
        IconView(icon: icon, tint: color)
            .frame(width: 200, height: 200)
            .previewLayout(.sizeThatFits)
            .previewDisplayName(icon.rawValue)
    }

}

#endif
