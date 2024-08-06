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

import SwiftUI

/// A SwiftUI view for displaying a message about unavailable content
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct CompatibilityContentUnavailableView: View {
    @State var title: String
    @State var description: String
    @State var systemImage: String

    var body: some View {

        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(description)
            )
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

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }.frame(maxHeight: .infinity)
        }

    }
}
