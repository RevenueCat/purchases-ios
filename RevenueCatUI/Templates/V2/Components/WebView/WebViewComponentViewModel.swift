//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewComponentViewModel.swift

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class WebViewComponentViewModel {

    let url: URL
    private let htmlFileRepository: InMemoryHTMLFileRepositoryType

    init(
        component: PaywallComponent.WebViewComponent,
        htmlFileRepository: InMemoryHTMLFileRepositoryType = InMemoryHTMLFileRepository.shared
    ) {
        self.url = component.url
        self.htmlFileRepository = htmlFileRepository
    }

    func displayURL() async -> URL {
        return await self.htmlFileRepository.getCachedFileURL(for: self.url) ?? self.url
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension WebViewComponentViewModel: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    static func == (lhs: WebViewComponentViewModel, rhs: WebViewComponentViewModel) -> Bool {
        lhs.url == rhs.url
    }

}

#endif
