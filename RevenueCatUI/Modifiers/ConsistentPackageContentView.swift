//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ConsistentPackageContentView.swift
//
//  Created by Nacho Soto on 9/22/23.
//

import SwiftUI

/// A wrapper view that can display content based on a selected package
/// and maintain a consistent layout when that selected package changes.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ConsistentPackageContentView<Content: View>: View {

    typealias Creator = @Sendable @MainActor (TemplateViewConfiguration.Package) -> Content

    private let packages: [TemplateViewConfiguration.Package]
    private let selected: TemplateViewConfiguration.Package
    private let creator: Creator

    init(
        packages: [TemplateViewConfiguration.Package],
        selected: TemplateViewConfiguration.Package,
        creator: @escaping Creator
    ) {
        self.packages = packages
        self.selected = selected
        self.creator = creator
    }

    var body: some View {
        // We need to layout all possible packages to accomodate for the longest text
        return ZStack {
            ForEach(self.packages, id: \.self.content) { package in
                self.creator(package)
                    .opacity(package.content == self.selected.content ? 1 : 0)
            }
        }
    }

}
