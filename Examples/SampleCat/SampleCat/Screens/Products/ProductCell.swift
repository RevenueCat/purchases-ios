//
//  ProductCell.swift
//  SampleCat
//
//  Created by Hidde van der Ploeg on 15/4/25.
//

import SwiftUI

struct ProductCell: View {
    @Environment(\.colorScheme) private var scheme
    let product: ProductViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(product.title ?? "")
                Spacer()
                Image(systemName: product.icon)
                    .foregroundStyle(product.color)
            }
            .font(.headline)
            .symbolRenderingMode(.hierarchical)
            Text(product.id)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(product.description)
                .font(.caption)
        }
        .padding()
        .background(scheme == .dark ? Color.black : Color.white)
        .clipShape(.rect(cornerRadius: 12))
    }
}
