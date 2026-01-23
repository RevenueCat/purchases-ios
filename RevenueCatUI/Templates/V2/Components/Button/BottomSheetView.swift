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

#if !os(tvOS) // For Paywalls V2

/// A view that presents content in a sheet-like interface with customizable height and background.
///
/// This view is designed to be used as a bottom sheet that slides up from the bottom of the screen.
/// It provides a scrollable container for its content with a fixed height and customizable background color.
///
/// - Note: This view is typically used in conjunction with ``BottomSheetOverlayModifier`` to present
///   content in a sheet-like interface.
///

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SheetViewModel: Equatable {
    let sheet: RevenueCat.PaywallComponent.ButtonComponent.Sheet
    let sheetStackViewModel: StackComponentViewModel

    static func == (lhs: SheetViewModel, rhs: SheetViewModel) -> Bool {
        lhs.sheet.id == rhs.sheet.id
    }
}

/// A view modifier that presents content in a sheet-like interface.
///
/// This modifier handles the presentation and dismissal of a sheet view, including
/// the animation and tap-to-dismiss behavior.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BottomSheetOverlayModifier: ViewModifier {
    @Binding var sheetViewModel: SheetViewModel?
    let safeAreaInsets: EdgeInsets

    @State private var parentHeight: CGFloat?

    var sheetHeight: CGFloat? {
        guard let size = self.sheetViewModel?.sheet.size else {
            return nil
        }

        switch size.height {
        case .fit, .fill:
            return nil
        case .fixed(let height):
            return CGFloat(height)
        case .relative(let percent):
            guard let parentHeight = self.parentHeight else {
                return nil
            }
            return parentHeight * percent
        }
    }

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: sheetViewModel?.sheet.backgroundBlur == true ? 10 : 0)
                .animation(.easeInOut(duration: 0.25), value: sheetViewModel?.sheet.backgroundBlur)

            // Invisible tap area that covers the screen
            if sheetViewModel != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sheetViewModel = nil
                    }
            }

            // Sheet content
            VStack {
                Spacer()
                if let sheetViewModel {
                    StackComponentView(
                        viewModel: sheetViewModel.sheetStackViewModel,
                        onDismiss: {
                            self.sheetViewModel = nil
                        },
                        additionalPadding: EdgeInsets(
                            top: 0,
                            leading: 0,
                            bottom: safeAreaInsets.bottom,
                            trailing: 0
                        )
                    )
                    .applyIfLet(self.sheetHeight, apply: { view, height in
                        view.frame(height: height)
                    })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            self.parentHeight = proxy.size.height
                        }
                }
            )
            .animation(.spring(response: 0.35, dampingFraction: 1), value: sheetViewModel)
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
    ///   - sheet: A binding to a SheetViewModel value that determines whether to present the sheet.
    ///   - content: A closure that returns the content of the sheet.
    ///
    /// - Returns: A view that presents the sheet when `isPresented` is true.
    func bottomSheet(
        sheet: Binding<SheetViewModel?>,
        safeAreaInsets: EdgeInsets
    ) -> some View {
        self.modifier(
            BottomSheetOverlayModifier(sheetViewModel: sheet, safeAreaInsets: safeAreaInsets)
        )
    }
}

#if DEBUG
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BottomSheetViewTestView: View {
    @State private var sheetViewModel: SheetViewModel? = .init(
        sheet: PaywallComponent.ButtonComponent.Sheet(
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
                backgroundColor: nil
            ),
            backgroundBlur: false,
            size: .init(width: .fill, height: .fit)
        ),
        // swiftlint:disable:next force_try
        sheetStackViewModel: try! .init(component: .init(
            components: [
                PaywallComponent.text(
                    PaywallComponent.TextComponent(
                        text: "buttonText",
                        color: .init(light: .hex("#000000"))
                    )
                )
            ],
            backgroundColor: .init(light: .hex("#FFFFFF"))
        ), localizationProvider: .init(
            locale: Locale.current,
            localizedStrings: [
                "buttonText": PaywallComponentsData.LocalizationData.string("Do something")
            ]
        ), colorScheme: .light
        )
    )
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.gray.opacity(0.2)

                VStack {
                    Text("This view will have a sheet over it")
                        .bottomSheet(sheet: $sheetViewModel,
                                     safeAreaInsets: proxy.safeAreaInsets)
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
        .previewRequiredPaywallsV2Properties()
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct BottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        BottomSheetViewTestView()
    }
}
#endif
#endif
