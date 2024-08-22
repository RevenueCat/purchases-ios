//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompatibilityContentUnavailableView.swift
//
//
//  Created by Cody Kerns on 8/6/24.
//

import Foundation
import SwiftUI

#if os(iOS)

/// A SwiftUI view for displaying a message about unavailable content
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CompatibilityContentUnavailableView: View {
    let title: String
    let systemImage: String
    let description: Text?

    init(_ title: String, systemImage: String, description: Text? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
    }

    var body: some View {

        if #available(iOS 17.0, *) {
            #if swift(>=5.9)
            if let description {
                ContentUnavailableView(
                    title,
                    systemImage: systemImage,
                    description: description
                )
            } else {
                ContentUnavailableView(
                    title,
                    systemImage: systemImage
                )
            }

            #else
                // In Xcode 14, any references to ContentUnavailableView would fail to compile since that entity
                // was included with Xcode 15 and later.
                // Although Xcode 15 is required for App Store builds, we have some CI processes that run in Xcode 14
                // so this retains compatibility while not affecting any real world usage.
                EmptyView()
            #endif
        } else {
            VStack {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(.secondary)
                    .padding()

                Text(title)
                    .font(.title2)
                    .bold()

                if let description {
                    description
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }.frame(maxHeight: .infinity)
        }

    }
}

#endif
