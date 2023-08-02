//
//  TemplateBackgroundImageView.swift
//  
//
//  Created by Nacho Soto on 8/1/23.
//

import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct TemplateBackgroundImageView: View {

    var configuration: TemplateViewConfiguration

    var body: some View {
        if let url = self.configuration.backgroundImageURL {
            self.image(url)
                .unredacted()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
        }
    }

    @ViewBuilder
    private func image(_ url: URL) -> some View {
        if self.configuration.configuration.blurredBackgroundImage {
            RemoteImage(url: url)
                .blur(radius: 40)
                .opacity(0.7)
        } else {
            RemoteImage(url: url)
        }
    }

}
