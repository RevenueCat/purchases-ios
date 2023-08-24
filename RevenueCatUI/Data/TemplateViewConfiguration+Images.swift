//
//  TemplateViewConfiguration+Images.swift
//  
//
//  Created by Nacho Soto on 7/25/23.
//

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TemplateViewConfiguration {

    var headerImageURL: URL? { self.url(for: \.header) }
    var backgroundImageURL: URL? { self.url(for: \.background) }
    var iconImageURL: URL? { self.url(for: \.icon) }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TemplateViewConfiguration {

    var backgroundImageURLToDisplay: URL? {
        guard self.mode.shouldDisplayBackground else { return nil }

        return self.backgroundImageURL
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension TemplateViewConfiguration {

    func url(for image: KeyPath<PaywallData.Configuration.Images, String?>) -> URL? {
        let imageName = self.configuration.images[keyPath: image]
        return imageName.map { self.assetBaseURL.appendingPathComponent($0) }
    }

}
