//
//  PackagesView.swift
//  SampleCat
//
//  Created by Hidde van der Ploeg on 7/4/25.
//

import SwiftUI

struct PackagesView: View {
    @Environment(UserViewModel.self) private var userViewModel

    var body: some View {
        NavigationStack {
            Text("Packages")
        }
        .navigationTitle("Packages")
    }
}

#Preview {
    PackagesView()
}
