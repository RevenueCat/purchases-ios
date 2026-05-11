//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultProductCell.swift
//
//  Created by Jacob Zivan Rakidzich on 12/14/25.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DefaultProductCell: View {
    let product: Package
    let accentColor: Color
    let selectedFontColor: Color
    @Binding var selected: Package?

    private var isSelected: Bool {
        selected == product
    }

    var body: some View {
        Button {
            withAnimation {
                selected = product
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .opacity(isSelected ? 1 : 0.5)
                    .accessibilityHidden(true)
                Text(product.storeProduct.localizedTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(product.localizedPriceString)
                    .font(.subheadline)
                    .monospacedDigit()
            }
            .foregroundColor(isSelected ? selectedFontColor : Color.primary)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? accentColor : .secondary.opacity(0.3))
            }
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
        .frame(maxWidth: 560)
    }
}
