//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootView.swift
//
//  Created by Jay Shortway on 24/10/2024.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RootView: View {

    @Environment(\.safeAreaInsets)
    private var safeAreaInsets

    @EnvironmentObject
    private var packageContext: PackageContext

    private let viewModel: RootViewModel
    private let onDismiss: () -> Void
    private let defaultPackage: Package?

    @State private var sheetViewModel: SheetViewModel?

    internal init(
        viewModel: RootViewModel,
        onDismiss: @escaping () -> Void,
        defaultPackage: Package?
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.defaultPackage = defaultPackage
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .top) {
                StackComponentView(
                    viewModel: viewModel.stackViewModel,
                    isScrollableByDefault: true,
                    onDismiss: onDismiss,
                    additionalPadding: EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: viewModel.stickyFooterViewModel == nil ? safeAreaInsets.bottom : 0,
                        trailing: 0
                    )
                )

                if let headerViewModel = viewModel.headerViewModel {
                    HeaderComponentView(
                        viewModel: headerViewModel,
                        onDismiss: onDismiss
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let stickyFooterViewModel = viewModel.stickyFooterViewModel {
                StackComponentView(
                    viewModel: stickyFooterViewModel.stackViewModel,
                    onDismiss: onDismiss,
                    additionalPadding: EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: safeAreaInsets.bottom,
                        trailing: 0
                    )
                )
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .environment(\.openSheet, { sheet in
            self.sheetViewModel = sheet
        })
        .bottomSheet(sheet: $sheetViewModel, safeAreaInsets: self.safeAreaInsets)
        .onChangeOf(sheetViewModel) { newValue in
            if newValue == nil {
                // Reset package selection to default when sheet is dismissed to prevent
                // purchasing a hidden package that was selected in the sheet
                packageContext.package = defaultPackage
            }
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum RootViewPreviewData {

    static let heroImageURL = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!
    static let safeAreaInsets = EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)

    static let offering = Offering(
        identifier: "preview",
        serverDescription: "",
        availablePackages: [],
        webCheckoutUrl: nil
    )

    static let localizationProvider: LocalizationProvider = .init(
        locale: .current,
        localizedStrings: [
            "paywall_title": .string("Unlock your smartest study routine"),
            "paywall_subtitle": .string("The header image should extend through the top safe area."),
            "header_title": .string("This header should start below the safe area")
        ]
    )

    static let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())

    static let bodyStack = PaywallComponent.StackComponent(
        components: [
            .stack(.init(
                components: [
                    .text(.init(
                        text: "paywall_title",
                        fontWeight: .black,
                        color: .init(light: .hex("#151515")),
                        padding: .zero,
                        margin: .zero,
                        fontSize: 32,
                        horizontalAlignment: .center
                    )),
                    .text(.init(
                        text: "paywall_subtitle",
                        color: .init(light: .hex("#5C5C5C")),
                        padding: .zero,
                        margin: .zero,
                        fontSize: 16,
                        horizontalAlignment: .center
                    ))
                ],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fit),
                spacing: 12,
                backgroundColor: .init(light: .hex("#FFFFFF")),
                padding: .init(top: 28, bottom: 28, leading: 24, trailing: 24),
                margin: .init(top: 280, bottom: 0, leading: 0, trailing: 0)
            ))
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fill),
        spacing: 0
    )

    static let heroHeaderStack = PaywallComponent.StackComponent(
        components: [
            .image(.init(
                source: .init(
                    light: .init(
                        width: 750,
                        height: 530,
                        original: heroImageURL,
                        heic: heroImageURL,
                        heicLowRes: heroImageURL
                    )
                ),
                size: .init(width: .fill, height: .fixed(300)),
                fitMode: .fill
            ))
        ],
        dimension: .zlayer(.top),
        size: .init(width: .fill, height: .fit),
        spacing: 0
    )

    static let textHeaderStack = PaywallComponent.StackComponent(
        components: [
            .text(.init(
                text: "header_title",
                fontWeight: .bold,
                color: .init(light: .hex("#FFFFFF")),
                backgroundColor: .init(light: .hex("#2D5BFF")),
                padding: .init(top: 20, bottom: 20, leading: 24, trailing: 24),
                margin: .zero,
                fontSize: 18,
                horizontalAlignment: .center
            ))
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fit),
        spacing: 0
    )

    static func rootViewModel(
        headerStack: PaywallComponent.StackComponent
    ) -> RootViewModel {
        var factory = ViewModelFactory()

        do {
            return try factory.toRootViewModel(
                componentsConfig: .init(
                    stack: self.bodyStack,
                    header: .init(stack: headerStack),
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#101321")))
                ),
                offering: self.offering,
                localizationProvider: self.localizationProvider,
                uiConfigProvider: self.uiConfigProvider,
                colorScheme: .light
            )
        } catch {
            fatalError("Invalid RootView preview configuration: \(error)")
        }
    }

    static func preview(
        headerStack: PaywallComponent.StackComponent,
        name: String
    ) -> some View {
        ZStack(alignment: .top) {
            Color.black

            RootView(
                viewModel: self.rootViewModel(headerStack: headerStack),
                onDismiss: {},
                defaultPackage: nil
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 393, height: 852)
        .previewRequiredPaywallsV2Properties()
        .environment(\.safeAreaInsets, self.safeAreaInsets)
        .emergeExpansion(false)
        .previewLayout(.fixed(width: 393, height: 852))
        .previewDisplayName(name)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RootView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            RootViewPreviewData.preview(
                headerStack: RootViewPreviewData.heroHeaderStack,
                name: "Header hero extends safe area"
            )

            RootViewPreviewData.preview(
                headerStack: RootViewPreviewData.textHeaderStack,
                name: "Header text respects safe area"
            )
        }
    }

}

#endif

#endif
