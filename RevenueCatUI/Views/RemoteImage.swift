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
    let maxWidth: CGFloat?

    init(url: URL, aspectRatio: Double? = nil, maxWidth: CGFloat? = nil) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.maxWidth = maxWidth
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
                        .frame(maxWidth: self.maxWidth)
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
                Group {
                    if let aspectRatio {
                        self.placeholderView
                            .aspectRatio(aspectRatio, contentMode: .fit)
                    } else {
                        self.placeholderView
                    }
                }
                .frame(maxWidth: self.maxWidth)
            }
        }
    }

    private var placeholderView: some View {
        Rectangle()
            .hidden()
    }

}
