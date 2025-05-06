//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BottomSheetView.swift
//
//  Created by Will Taylor on 5/5/25.

import SwiftUI

import RevenueCat

#if !os(macOS) && !os(tvOS) // For Paywalls V2

/// A view that presents content in a sheet-like interface with customizable height and background.
///
/// This view is designed to be used as a bottom sheet that slides up from the bottom of the screen.
/// It provides a scrollable container for its content with a fixed height and customizable background color.
///
/// - Note: This view is typically used in conjunction with ``BottomSheetOverlayModifier`` to present
///   content in a sheet-like interface.

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BottomSheetView<Content: View>: View {

    /// The height of the sheet.
    let height: CGFloat

    /// The content to be displayed within the sheet.
    let content: Content

    /// Creates a new sheet view with the specified parameters.
    ///
    /// - Parameters:
    ///   - backgroundColor: The background color of the sheet.
    ///   - height: The height of the sheet.
    ///   - content: A view builder closure that creates the content of the sheet.
    init(
        height: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.height = height
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical) {
            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    EmptyView()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: height)
    }
}

/// A view modifier that presents content in a sheet-like interface.
///
/// This modifier handles the presentation and dismissal of a sheet view, including
/// the animation and tap-to-dismiss behavior.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BottomSheetOverlayModifier: ViewModifier {
    /// A binding to a Boolean value that determines whether the sheet is presented.
    @Binding var sheet: RevenueCat.PaywallComponent.ButtonComponent.Sheet?
    let sheetStackViewModel: StackComponentViewModel?
    @State private var sheetHeight: CGFloat = 0

    func body(content: Content) -> some View {
        if let sheetStackViewModel {
            modifierBody(content: content, sheetStackViewModel: sheetStackViewModel)
                .ignoresSafeArea()
        } else {
            content
        }
    }

    var backgroundStyle: BackgroundStyle? {
        if let sheet, let sheetStackViewModel {
            sheet.background?.asDisplayable(uiConfigProvider: sheetStackViewModel.uiConfigProvider)
        } else {
            nil
        }
    }

    @ViewBuilder
    private func modifierBody(
        content: Content,
        sheetStackViewModel: StackComponentViewModel
    ) -> some View {
        ZStack {
            content
                .blur(radius: sheet?.backgroundBlur ?? false ? 10 : 0)
            // Invisible tap area that covers the screen
            if sheet != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sheet = nil
                    }
            }

            // Sheet content
            VStack {
                Spacer()
                if self.sheet != nil {
                    BottomSheetView(
                        height: self.sheetHeight
                    ) {
                        StackComponentView(
                            viewModel: sheetStackViewModel,
                            onDismiss: {
                                self.sheet = nil
                            }
                        )
                    }
                    .backgroundStyle(backgroundStyle)
                    .transition(.move(edge: .bottom))
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            self.sheetHeight = proxy.size.height * 0.33333
                        }
                }
            )
            .animation(.spring(duration: 0.35), value: sheet)
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    /// Presents a sheet view when a binding to a Boolean value is true.
    ///
    /// Use this modifier to present a sheet view that slides up from the bottom of the screen.
    /// The sheet can be dismissed by setting the binding to `false` or by tapping outside
    /// the sheet (if `tapOutsideToDismiss` is enabled in the configuration).
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether to present the sheet.
    ///   - config: The configuration for the sheet. Defaults to a configuration with
    ///     system background color and one-third screen height.
    ///   - content: A closure that returns the content of the sheet.
    ///
    /// - Returns: A view that presents the sheet when `isPresented` is true.
    func bottomSheet(
        sheet: Binding<RevenueCat.PaywallComponent.ButtonComponent.Sheet?>,
        sheetStackViewModel: StackComponentViewModel?
    ) -> some View {
        modifier(
            BottomSheetOverlayModifier(sheet: sheet, sheetStackViewModel: sheetStackViewModel)
        )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
#Preview {
    struct Preview: View {
        @State private var sheet: PaywallComponent.ButtonComponent.Sheet? = PaywallComponent.ButtonComponent.Sheet(
            id: "exampleSheet",
            name: nil,
            stack: .init(
                components: [
                    PaywallComponent.text(
                        PaywallComponent.TextComponent(
                            text: "buttonText",
                            color: .init(light: .hex("#000000"))
                        )
                    )
                ],
                backgroundColor: nil,
            ),
            background: .color(.init(light: .hex("#000aaa"))),
            backgroundBlur: false
        )

        var body: some View {
            ZStack {
                Color.gray.opacity(0.2)

                VStack {
                    Text("This view will have a sheet over it")
                        .bottomSheet(
                            sheet: $sheet,
                            sheetStackViewModel: {
                                let factory = ViewModelFactory()
                                // swiftlint:disable:next force_try
                                return try! factory.toStackViewModel(
                                    component: .init(
                                        components: [
                                            PaywallComponent.text(
                                                PaywallComponent.TextComponent(
                                                    text: "buttonText",
                                                    color: .init(light: .hex("#000000"))
                                                )
                                            )
                                        ],
                                        size: .init(width: .fill, height: .fill),
                                        backgroundColor: .init(light: .hex("#ab56ab"))
                                    ),
                                    packageValidator: factory.packageValidator,
                                    firstImageInfo: nil,
                                    localizationProvider: .init(
                                        locale: Locale.current,
                                        localizedStrings: [
                                            "buttonText": PaywallComponentsData.LocalizationData.string("Do something")
                                        ]
                                    ),
                                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                                    offering: Offering(identifier: "", serverDescription: "", availablePackages: [])
                                )

                            }()
                        )
                }
            }
            .edgesIgnoringSafeArea(.all)
            .previewRequiredEnvironmentProperties()
        }
    }

    return Preview()
}
#endif
