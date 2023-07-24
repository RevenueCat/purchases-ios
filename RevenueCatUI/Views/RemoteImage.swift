//
//  RemoteImage.swift
//  
//
//  Created by Nacho Soto on 7/19/23.
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct RemoteImage: View {

    let url: URL
    let aspectRatio: Double?

    init(url: URL, aspectRatio: Double? = nil) {
        self.url = url
        self.aspectRatio = aspectRatio
    }

    var body: some View {
        AsyncImage(
            url: self.url,
            transaction: .init(animation: Constants.defaultAnimation)
        ) { phase in
            if let image = phase.image {
                if let aspectRatio {
                    image
                        .fitToAspect(aspectRatio, contentMode: .fill)
                } else {
                    image
                        .resizable()
                }
            } else if let error = phase.error {
                DebugErrorView("Error loading image from '\(self.url)': \(error)",
                               releaseBehavior: .emptyView)
                .font(.footnote)
                .textCase(.none)
            } else {
                Rectangle()
                    .hidden()
            }
        }
    }

}
