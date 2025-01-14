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

#if PAYWALL_COMPONENTS

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
                guard let baseUrl = URL(string: icon.baseUrl) else {
                    break
                }

                urls += icon.formats.imageUrls(base: baseUrl)
                urls += icon.overrides?.imageUrls(base: baseUrl) ?? []
            case .image(let image):
                urls += [
                    image.source.light.heicLowRes,
                    image.source.dark?.heicLowRes
                ].compactMap { $0 }

                if let overides = image.overrides {
                    urls += [
                        overides.introOffer?.source?.imageUrls ?? [],
                        overides.states?.selected?.source?.imageUrls ?? [],
                        overides.conditions?.compact?.source?.imageUrls ?? [],
                        overides.conditions?.medium?.source?.imageUrls ?? [],
                        overides.conditions?.expanded?.source?.imageUrls ?? []
                    ].flatMap { $0 }
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

extension PaywallComponent.ComponentOverrides where T == PaywallComponent.PartialIconComponent {

    func imageUrls(base: URL) -> [URL] {
        return [
            self.introOffer?.formats?.imageUrls(base: base) ?? [],
            self.states?.selected?.formats?.imageUrls(base: base) ?? [],
            self.conditions?.compact?.formats?.imageUrls(base: base) ?? [],
            self.conditions?.medium?.formats?.imageUrls(base: base) ?? [],
            self.conditions?.expanded?.formats?.imageUrls(base: base) ?? []
        ].flatMap { $0 }
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

#endif
