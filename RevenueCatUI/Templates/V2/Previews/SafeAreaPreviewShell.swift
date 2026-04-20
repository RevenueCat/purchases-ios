//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SafeAreaPreviewShell.swift
//
//  Created by RevenueCat on 4/15/26.
//

import SwiftUI

#if !os(tvOS) // For Paywalls V2

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum SafeAreaPreviewMetrics {

    static let previewSize = CGSize(width: 425, height: 936)
    static let deviceSize = CGSize(width: 393, height: 852)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SafeAreaPreviewShell<Content: View>: View {

    let title: String
    let subtitle: String
    let previewDisplayName: String
    let safeAreaInsets: EdgeInsets

    private let content: Content

    init(
        title: String,
        subtitle: String,
        previewDisplayName: String,
        safeAreaInsets: EdgeInsets,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.previewDisplayName = previewDisplayName
        self.safeAreaInsets = safeAreaInsets
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white

            self.content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .environment(\.safeAreaInsets, safeAreaInsets)
        .overlay {
            VStack(spacing: 4) {
                Spacer()
                Spacer()
                VStack {
                    Text(self.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.black)
                        .multilineTextAlignment(.center)

                    Text(self.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(Color.red.opacity(0.3))
                .clipShape(RoundedRectangle(cornerSize: .init(width: 12, height: 12)))
                .overlay {
                    RoundedRectangle(cornerSize: .init(width: 12, height: 12))
                        .stroke(.red.opacity(0.5), style: .init(lineWidth: 2))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

        }
        .overlay {
            SafeAreaGuideOverlay(safeAreaInsets: self.safeAreaInsets)
        }
        .frame(width: SafeAreaPreviewMetrics.previewSize.width, height: SafeAreaPreviewMetrics.previewSize.height)
        .background(Color.white)
        .previewRequiredPaywallsV2Properties()
        .environment(\.safeAreaInsets, self.safeAreaInsets)
        .emergeExpansion(false)
        .previewLayout(.fixed(width: SafeAreaPreviewMetrics.previewSize.width,
                              height: SafeAreaPreviewMetrics.previewSize.height))
        .previewDisplayName(self.previewDisplayName)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct SafeAreaGuideOverlay: View {

    private static let guideColor1 = Color.pink
    private static let guideColor2 = Color.black

    let safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(spacing: 0) {
            if self.safeAreaInsets.top > 0 {
                Self.guideRegion(
                    height: self.safeAreaInsets.top,
                    boundaryAlignment: .bottom
                )
            }

            Spacer(minLength: 0)

            if self.safeAreaInsets.bottom > 0 {
                Self.guideRegion(
                    height: self.safeAreaInsets.bottom,
                    boundaryAlignment: .top
                )
            }
        }
        .allowsHitTesting(false)
    }

    private static func guideRegion(
        height: CGFloat,
        boundaryAlignment: VerticalAlignment
    ) -> some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: boundaryAlignment)) {
            HStack(spacing: 0) {
                ForEach((0..<100)) { _ in
                    Self.guideColor1.opacity(0.12)
                    Self.guideColor2.opacity(0.12)

                }
                .rotationEffect(.degrees(12))
            }
            .scaleEffect(2)
            .clipped()

            Rectangle()
                .fill(Self.guideColor1.opacity(0.55))
                .frame(height: 1)
        }
        .frame(height: height)
    }

}

#endif

#endif
