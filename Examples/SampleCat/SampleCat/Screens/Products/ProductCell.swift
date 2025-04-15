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
            }
            .font(.headline)
            .symbolRenderingMode(.hierarchical)

            Text(product.description)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(scheme == .dark ? Color.black : Color.white)
        .clipShape(.rect(cornerRadius: 12))
    }
}
