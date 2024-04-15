//
//  AppList.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-13.
//

import SwiftUI

struct AppList: View {
    
    let developer: DeveloperResponse
    
    var body: some View {
        NavigationView {
            List {
                ForEach(developer.apps, id: \.id) { app in
                    NavigationLink("\(app.name)") {
                        OfferingsList(app: app)
                    }
                }
            }.navigationTitle("Live Apps")
        }
    }
}

#Preview {
    AppList(developer: MockData.developer())
}
