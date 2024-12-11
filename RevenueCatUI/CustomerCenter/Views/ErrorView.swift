//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ErrorView.swift
//
//  Created by Cesar de la Vega on 11/12/24.

import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ErrorView: View {

    @Environment(\.locale)
    private var locale

    var body: some View {
        VStack(spacing: 20) {
            let errorMessage: String = Localization.localizedBundle(self.locale)
                .localizedString(forKey: "Something went wrong",
                                 value: "Something went wrong",
                                 table: nil)
            CompatibilityContentUnavailableView(
                String(errorMessage),
                systemImage: "exclamationmark.triangle.fill",
                description: nil
            )
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ErrorView_Previews: PreviewProvider {

    static var previews: some View {
        ErrorView()
    }
}
#endif

#endif
