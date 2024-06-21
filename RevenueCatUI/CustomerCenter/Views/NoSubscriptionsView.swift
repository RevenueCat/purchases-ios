//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NoSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct NoSubscriptionsView: View {

    // swiftlint:disable:next todo
    // TODO: build screen using this configuration
    let configuration: CustomerCenterConfigData

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @State
    private var showRestoreAlert: Bool = false

    init(configuration: CustomerCenterConfigData) {
        self.configuration = configuration
    }

    // swiftlint:disable:next todo
    // TODO: build screen using this configuration
    private let configuration: CustomerCenterConfigData

    @Environment(\.dismiss)
    private var dismiss
    @State
    private var showRestoreAlert: Bool = false

    var body: some View {
        VStack {
            Text(localization.commonLocalizedString(for: .noSubscriptionsFound))
                .font(.title)
                .padding()
            Text(localization.commonLocalizedString(for: .tryCheckRestore))
                .font(.body)
                .padding()

            Spacer()

            Button(localization.commonLocalizedString(for: .restorePurchases)) {
                showRestoreAlert = true
            }
            .restorePurchasesAlert(isPresented: $showRestoreAlert)
            .buttonStyle(ManageSubscriptionsButtonStyle(appearance: self.configuration.appearance))

            Button(localization.commonLocalizedString(for: .cancel)) {
                dismiss()
            }
        }

    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct NoSubscriptionsView_Previews: PreviewProvider {

    static var previews: some View {
        NoSubscriptionsView(configuration: CustomerCenterConfigTestData.customerCenterData)
    }

}

#endif

#endif
