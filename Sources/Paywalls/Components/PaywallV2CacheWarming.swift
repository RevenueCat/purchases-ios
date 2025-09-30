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
        let stickFooterImageURLs = self.stickyFooter.flatMap {
            self.collectAllImageURLs(in: $0.stack)
        } ?? []

        return rootStackImageURLs + stickFooterImageURLs
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func collectAllImageURLs(
    in stack: PaywallComponent.StackComponent,
    includeHighResInComponentHeirarchy: (PaywallComponent) -> Bool = { component in
        // collecting high res images from the sheet is important because async functions
        // prevent the proper animation from playing during sheet presentation and by collecting
        // the images ahead of time we can synchronously render the image instead.
        return component.isSheetButton
    }
    ) -> [URL] {

        var urls: [URL] = []
        for component in stack.components {
            var includeHighResInComponentHeirarchy = includeHighResInComponentHeirarchy
            if includeHighResInComponentHeirarchy(component) {
                // override to true regardless of children to ensure high res
                // image collection after the desired component type was found
                includeHighResInComponentHeirarchy = { _ in return true }
            }

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

                if includeHighResInComponentHeirarchy(component) {
                    urls += image.source.highResImageUrls
                }

            case .stack(let stack):
                urls += self.collectAllImageURLs(
                    in: stack,
                    includeHighResInComponentHeirarchy: includeHighResInComponentHeirarchy
                )
            case .button(let button):
                urls += self.collectAllImageURLs(
                    in: button.stack,
                    includeHighResInComponentHeirarchy: includeHighResInComponentHeirarchy
                )

                // Collect images from sheet stack
                switch button.action {
                case .navigateTo(let destination):
                    switch destination {
                    case .sheet(sheet: let sheet):
                        urls += self.collectAllImageURLs(
                            in: sheet.stack,
                            includeHighResInComponentHeirarchy: includeHighResInComponentHeirarchy
                        )
                    case .customerCenter, .offerCode, .privacyPolicy, .terms, .webPaywallLink, .url, .unknown:
                        break
                    }
                case .restorePurchases, .navigateBack, .unknown:
                    break
                }
            case .package(let package):
                urls += self.collectAllImageURLs(
                    in: package.stack,
                    includeHighResInComponentHeirarchy: includeHighResInComponentHeirarchy
                )
            case .purchaseButton(let purchaseButton):
                urls += self.collectAllImageURLs(
                    in: purchaseButton.stack,
                    includeHighResInComponentHeirarchy: includeHighResInComponentHeirarchy
                )
            case .stickyFooter(let stickyFooter):
                urls += self.collectAllImageURLs(
                    in: stickyFooter.stack,
                    includeHighResInComponentHeirarchy: includeHighResInComponentHeirarchy
                )
            case .timeline(let component):
                for item in component.items {
                    urls += item.icon.imageUrls
                }
            case .tabs(let tabs):
                for tab in tabs.tabs {
                    urls += self.collectAllImageURLs(
                        in: tab.stack,
                        includeHighResInComponentHeirarchy: includeHighResInComponentHeirarchy
                    )
                }
            case .tabControl:
                break
            case .tabControlButton(let controlButton):
                urls += self.collectAllImageURLs(
                    in: controlButton.stack,
                    includeHighResInComponentHeirarchy: includeHighResInComponentHeirarchy
                )
            case .tabControlToggle:
                break
            case .carousel(let carousel):
                urls += carousel.pages.flatMap(
                    { stack in
                        self.collectAllImageURLs(
                            in: stack,
                            includeHighResInComponentHeirarchy: includeHighResInComponentHeirarchy
                        )
                })
            case .video:
                // WIP: - prewarm cache
                break
            }
        }

        return urls
    }

}

private extension PaywallComponent {
    var isSheetButton: Bool {
        switch self {
        case .button(let component):
            switch component.action {
            case .navigateTo(.sheet):
                return true
            default:
                return false
            }
        default:
            return false
        }
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

    var highResImageUrls: [URL] {
        return [
            self.light.heic,
            self.dark?.heic
        ].compactMap { $0 }
    }

}
