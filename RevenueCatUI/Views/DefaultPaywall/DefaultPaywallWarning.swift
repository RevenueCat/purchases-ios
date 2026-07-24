//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultPaywallWarning.swift
//
//  Created by Jacob Zivan Rakidzich on 12/14/25.

import RevenueCat
import SwiftUI

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DefaultPaywallWarning: View {
    let warning: PaywallWarning

    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .center, spacing: 16) {

            Image("default-paywall", bundle: .revenueCatUI)
                .accessibilityHidden(true)

            VStack(alignment: .center, spacing: 8) {
                Text(warning.title)
                    .font(.title3)
                    .bold()
                Text(warning.bodyText)
                    .font(.subheadline)
            }
            if let url = warning.helpURL {
                let link = Link(destination: url) {
                    Text("Go to Dashboard")
                        .bold()
                }.buttonStyle(.bordered)

                if #available(watchOS 9.0, *) {
                    link.tint(.revenueCatBrandRed)
                } else {
                    link.foregroundStyle(Color.revenueCatBrandRed)
                }
            }

            if let copyableText = warning.copyableText, Pasteboard.isAvailable {
                self.copyButton(for: copyableText)
            }

        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private func copyButton(for text: String) -> some View {
        let button = Button {
            Pasteboard.copy(text)
            withAnimation { self.didCopy = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { self.didCopy = false }
            }
        } label: {
            Label(self.didCopy ? "Copied" : "Copy error details",
                  systemImage: self.didCopy ? "checkmark" : "doc.on.doc")
                .font(.body.bold())
        }.buttonStyle(.bordered)

        if #available(watchOS 9.0, *) {
            button.tint(.revenueCatBrandRed)
        } else {
            button.foregroundStyle(Color.revenueCatBrandRed)
        }
    }
}

/// Small cross-platform wrapper around the system pasteboard.
///
/// tvOS and watchOS don't provide a pasteboard, so `isAvailable` is `false` there and
/// `copy(_:)` is a no-op. Callers should check `isAvailable` before offering copy affordances.
enum Pasteboard {

    static var isAvailable: Bool {
        #if os(iOS) || os(visionOS) || os(macOS)
        return true
        #else
        return false
        #endif
    }

    static func copy(_ string: String) {
        #if os(iOS) || os(visionOS)
        UIPasteboard.general.string = string
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }

}
