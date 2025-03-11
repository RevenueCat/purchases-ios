//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallV2CacheWarming.swift
//
//  Created by Josh Holtz on 1/13/25.

import Foundation

extension PaywallComponentsData {

    var allImageURLs: [URL] {
        var imageUrls = self.componentsConfig.base.allImageURLs

        for (_, localeValues) in self.componentsLocalizations {
            for (_, value) in localeValues {
                switch value {
                case .string:
                    break
                case .image(let image):
                    imageUrls += image.imageUrls
                }
            }
        }

        return imageUrls
    }

}

extension PaywallComponentsData.PaywallComponentsConfig {

    var allImageURLs: [URL] {
        let rootStackImageURLs = self.collectAllImageURLs(in: self.stack)
        let stickFooterImageURLs = self.stickyFooter.flatMap { self.collectAllImageURLs(in: $0.stack) } ?? []

        return rootStackImageURLs + stickFooterImageURLs
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func collectAllImageURLs(in stack: PaywallComponent.StackComponent) -> [URL] {

        var urls: [URL] = []
        for component in stack.components {
            switch component {
            case .text:
                ()
            case .icon(let icon):
                urls += icon.imageUrls
            case .image(let image):
                urls += image.source.imageUrls

                if let overrides = image.overrides {
                    urls += overrides.imageUrls
                }
            case .stack(let stack):
                urls += self.collectAllImageURLs(in: stack)
            case .button(let button):
                urls += self.collectAllImageURLs(in: button.stack)
            case .package(let package):
                urls += self.collectAllImageURLs(in: package.stack)
            case .purchaseButton(let purchaseButton):
                urls += self.collectAllImageURLs(in: purchaseButton.stack)
            case .stickyFooter(let stickyFooter):
                urls += self.collectAllImageURLs(in: stickyFooter.stack)
            case .timeline(let component):
                for item in component.items {
                    urls += item.icon.imageUrls
                }
            case .tabs(let tabs):
                for tab in tabs.tabs {
                    urls += self.collectAllImageURLs(in: tab.stack)
                }
            case .tabControl:
                break
            case .tabControlButton(let controlButton):
                urls += self.collectAllImageURLs(in: controlButton.stack)
            case .tabControlToggle:
                break
            case .carousel(let carousel):
                urls += carousel.pages.flatMap({ stack in
                    self.collectAllImageURLs(in: stack)
                })
            }
        }

        return urls
    }

}

extension PaywallComponent.IconComponent.Formats {

    func imageUrls(base: URL) -> [URL] {
        return [
            base.appendingPathComponent(heic)
        ]
    }

}

private extension PaywallComponent.IconComponent {

    var imageUrls: [URL] {
        guard let baseUrl = URL(string: self.baseUrl) else {
            return []
        }

        return self.formats.imageUrls(base: baseUrl) + (self.overrides?.imageUrls(base: baseUrl) ?? [])
    }

}

extension Array where Element == PaywallComponent.ComponentOverride<PaywallComponent.PartialIconComponent> {

    func imageUrls(base: URL) -> [URL] {
        return self.compactMap { iconOverrides in
            iconOverrides.properties.formats?.imageUrls(base: base) ?? []
        }.flatMap { $0 }
    }

}

extension Array where Element == PaywallComponent.ComponentOverride<PaywallComponent.PartialImageComponent> {

    var imageUrls: [URL] {
        return self.compactMap { iconOverrides in
            iconOverrides.properties.source?.imageUrls ?? []
        }.flatMap { $0 }
    }

}

private extension PaywallComponent.ThemeImageUrls {

    var imageUrls: [URL] {
        return [
            self.light.heicLowRes,
            self.dark?.heicLowRes
        ].compactMap { $0 }
    }

}
