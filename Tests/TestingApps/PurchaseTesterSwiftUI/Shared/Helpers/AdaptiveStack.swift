//
//  AdaptiveStack.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 6/22/23.
//

import SwiftUI

struct AdaptiveStack<Content: View>: View {

    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: () -> Content

    init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        #if os(visionOS)
        VStack(alignment: self.horizontalAlignment, spacing: self.spacing, content: self.content)
        #else
        HStack(alignment: self.verticalAlignment, spacing: spacing, content: self.content)
        #endif
    }
}
