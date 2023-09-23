//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TemplateViewConfiguration+Images.swift
//
//  Created by Nacho Soto on 7/25/23.

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateViewConfiguration {

    var headerImageURL: URL? { self.url(for: \.header) }
    var backgroundImageURL: URL? { self.url(for: \.background) }
    var iconImageURL: URL? { self.url(for: \.icon) }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateViewConfiguration {

    var backgroundImageURLToDisplay: URL? {
        guard self.mode.shouldDisplayBackground else { return nil }

        return self.backgroundImageURL
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension TemplateViewConfiguration {

    func url(for image: KeyPath<PaywallData.Configuration.Images, String?>) -> URL? {
        return PaywallData.url(
            for: image,
            in: self.configuration.images,
            assetBaseURL: self.assetBaseURL
        )
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension PaywallData {

    var headerImageURL: URL? { self.url(for: \.header) }
    var backgroundImageURL: URL? { self.url(for: \.background) }
    var iconImageURL: URL? { self.url(for: \.icon) }

    private func url(for image: KeyPath<PaywallData.Configuration.Images, String?>) -> URL? {
        return PaywallData.url(
            for: image,
            in: self.config.images,
            assetBaseURL: self.assetBaseURL
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallData {

    static func url(
        for image: KeyPath<PaywallData.Configuration.Images, String?>,
        in images: PaywallData.Configuration.Images,
        assetBaseURL: URL
    ) -> URL? {
        return images[keyPath: image].map { assetBaseURL.appendingPathComponent($0) }
    }

}
