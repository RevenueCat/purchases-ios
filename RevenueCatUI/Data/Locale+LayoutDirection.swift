//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Locale+LayoutDirection.swift
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

extension Locale {

    var rcLayoutDirection: LayoutDirection {
        #if swift(>=5.9) && os(visionOS)
        return self.language.characterDirection.rcLayoutDirection
        #else
        #if swift(>=5.9)
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
            return self.language.characterDirection.rcLayoutDirection
        }
        #endif

        return Locale.characterDirection(forLanguage: self.identifier).rcLayoutDirection
        #endif
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallLayoutDirectionResolver {

    typealias EditorLayoutDirection = PaywallComponentsData.PaywallComponentsConfig.LayoutDirection

    static func resolve(
        editorLayoutDirection: EditorLayoutDirection?,
        preferredLocale: Locale?,
        honorsPreferredLocaleLayoutDirection: Bool
    ) -> LayoutDirection? {
        switch editorLayoutDirection {
        case .rtl:
            return .rightToLeft
        case .ltr:
            return .leftToRight
        case .locale:
            return (preferredLocale ?? .current).rcLayoutDirection
        case .system, .none:
            guard honorsPreferredLocaleLayoutDirection else {
                return nil
            }
            return (preferredLocale ?? .current).rcLayoutDirection
        }
    }

}

extension View {

    @ViewBuilder
    func rcApplyLayoutDirection(_ layoutDirection: LayoutDirection?) -> some View {
        if let layoutDirection {
            self.environment(\.layoutDirection, layoutDirection)
        } else {
            self
        }
    }

}

private extension Locale.LanguageDirection {

    var rcLayoutDirection: LayoutDirection {
        switch self {
        case .rightToLeft:
            return .rightToLeft
        default:
            return .leftToRight
        }
    }

}
