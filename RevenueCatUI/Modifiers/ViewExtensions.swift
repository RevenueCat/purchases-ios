////
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ViewExtensions.swift
//
//  Created by Nacho Soto on 7/13/23.

// swiftlint:disable file_length

import Foundation
import SwiftUI

extension View {

    @ViewBuilder
    func hidden(if condition: Bool) -> some View {
        if condition {
            self.hidden()
        } else {
            self
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Wraps the 2 `onChange(of:)` implementations in iOS 17+ and below depending on what's available
    @inlinable
    @ViewBuilder
    func onChangeOf<V>(
        _ value: V,
        perform action: @escaping (_ newValue: V) -> Void
    ) -> some View where V: Equatable {
        #if swift(>=5.9)
        // wrapping with AnyView to type erase is needed because when archiving an xcframework,
        // the compiler gets confused between the types returned
        // by the different implementations of self.onChange(of:value).
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            AnyView(self.onChange(of: value) { _, newValue in action(newValue) })
        } else {
            AnyView(self.onChange(of: value) { newValue in action(newValue) })
        }
        #else
        self.onChange(of: value) { newValue in action(newValue) }
        #endif
    }

}

enum ChangeOf<Value> {
    case new(Value)
    case changed(old: Value, new: Value)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    @ViewBuilder
    func onChangeOfWithChange<V>(
        _ value: V,
        perform action: @escaping (_ change: ChangeOf<V>) -> Void
    ) -> some View where V: Equatable {
        #if swift(>=5.9)
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            AnyView(self.onChange(of: value) { old, new in
                action(.changed(old: old, new: new))
            })
        } else {
            AnyView(self.onChange(of: value) { new in
                action(.new(new))
            })
        }
        #else
        self.onChange(of: value) { new in
            action(.new(new))
        }
        #endif
    }

}

// MARK: - Scrolling

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    @ViewBuilder
    func scrollable(
        _ axes: Axis.Set = .vertical,
        if condition: Bool
    ) -> some View {
        if condition {
            ScrollView(axes) {
                self
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func scrollBounceBehaviorBasedOnSize() -> some View {
        #if swift(>=5.8)
        if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
            self.scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
        #else
        self
        #endif
    }

    @ViewBuilder
    func scrollableIfNecessary(_ axis: Axis = .vertical, enabled: Bool = true) -> some View {
        if enabled {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                ViewThatFits(in: axis.scrollViewAxis) {
                    self

                    ScrollView(axis.scrollViewAxis) {
                        self
                    }
                }
            } else {
                self.modifier(ScrollableIfNecessaryModifier(axis: axis))
            }
        } else {
            self
        }
    }

    /// Equivalent to `scrollableIfNecessary` except that it's always scrollable on iOS 15
    /// to work around issues with that iOS 15 implementation in some instances.
    ///
    /// fillContent: true means that the view will try to fill the space available.
    /// fillContent: false means that the view will try to fit in the space available.
    @ViewBuilder
    func scrollableIfNecessaryWhenAvailable(
        _ axis: Axis = .vertical,
        fillContent: Bool,
        alignment: Alignment
    ) -> some View {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            if fillContent {
                // For FILL content: use ViewThatFits to avoid scrolling when possible
                // and to be able to fill the space available and align the content
                ViewThatFits(in: axis.scrollViewAxis) {
                    // When content is short: expand to fill space with alignment
                    self
                        .frame(
                            maxWidth: axis == .horizontal ? .infinity : nil,
                            maxHeight: axis == .vertical ? .infinity : nil,
                            alignment: alignment
                        )

                    // When content is too long: scroll it
                    ScrollView(axis.scrollViewAxis) {
                        self
                    }
                    .scrollBounceBehaviorBasedOnSize()
                }
            } else {
                // For FIT content: just use ScrollView (sizes naturally, scrolls if needed)
                ScrollView(axis.scrollViewAxis) {
                    self
                }
                .scrollBounceBehaviorBasedOnSize()
            }
        } else {
            self
                .centeredContent(axis)
                .scrollable(if: true)
        }
    }

    /// Equivalent to `scrollableIfNecessary` except that it's always scrollable on iOS 15
    /// to work around issues with that iOS 15 implementation in some instances.
    /// This function should be used by v1 paywalls since it doesn't respect fit/fill configurations
    @ViewBuilder
    func scrollableIfNecessaryWhenAvailableForV1(
        _ axis: Axis = .vertical,
        enabled: Bool = true
    ) -> some View {
        if enabled {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                ViewThatFits(in: axis.scrollViewAxis) {
                    self

                    ScrollView(axis.scrollViewAxis) {
                        self
                    }
                    .scrollBounceBehaviorBasedOnSize()
                }
            } else {
                self
                    .centeredContent(axis)
                    .scrollable(if: enabled)
            }
        } else {
            self
        }
    }

    @ViewBuilder
    fileprivate func centeredContent(_ axis: Axis) -> some View {
        switch axis {
        case .horizontal:
            HStack {
                Spacer()
                self
                Spacer()
            }
        case .vertical:
            VStack {
                Spacer()
                self
                Spacer()
            }
        }
    }

}

// MARK: - Padding

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    func defaultHorizontalPadding() -> some View {
        return self.modifier(DefaultHorizontalPaddingModifier())
    }

    func defaultVerticalPadding() -> some View {
        return self.modifier(DefaultVerticalPaddingModifier())
    }

    func defaultPadding() -> some View {
        return self
            .defaultHorizontalPadding()
            .defaultVerticalPadding()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct DefaultHorizontalPaddingModifier: ViewModifier {

    @Environment(\.userInterfaceIdiom)
    private var interfaceIdiom

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Constants.defaultHorizontalPaddingLength(self.interfaceIdiom))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct DefaultVerticalPaddingModifier: ViewModifier {

    @Environment(\.userInterfaceIdiom)
    private var interfaceIdiom

    func body(content: Content) -> some View {
        content
            .padding(.vertical, Constants.defaultVerticalPaddingLength(self.interfaceIdiom))
    }

}

// MARK: - scrollableIfNecessary

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ScrollableIfNecessaryModifier: ViewModifier {

    var axis: Axis

    @State
    private var overflowing: Bool = false

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .centeredContent(self.axis)
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear
                            .onAppear {
                                switch self.axis {
                                case .horizontal:
                                    self.overflowing = contentGeometry.size.width > geometry.size.width
                                case .vertical:
                                    self.overflowing = contentGeometry.size.height > geometry.size.height
                                }
                            }
                    }
                )
        }
        .scrollable(self.axis.scrollViewAxis, if: self.overflowing)
        .scrollBounceBehaviorBasedOnSize()
    }

}

// MARK: - Size changes

extension View {

    /// Invokes the given closure whethever the view size changes.
    func onSizeChange(_ closure: @escaping (CGSize) -> Void) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ViewSizePreferenceKey.self,
                                    value: geometry.size)
                }
            )
            .onPreferenceChange(ViewSizePreferenceKey.self, perform: closure)
    }

    /// Invokes the given closure with the view width whenever it changes.
    @ViewBuilder
    func onWidthChange(
        _ closure: @escaping (CGFloat) -> Void
    ) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ViewWidthPreferenceKey.self,
                            value: geometry.size.width
                        )
                }
            )
            .onPreferenceChange(ViewWidthPreferenceKey.self, perform: closure)
    }

    /// Invokes the given closure with the view height whenever it changes.
    @ViewBuilder
    func onHeightChange(
        _ closure: @escaping (CGFloat) -> Void
    ) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ViewHeightPreferenceKey.self,
                            value: geometry.size.height
                        )
                }
            )
            .onPreferenceChange(ViewHeightPreferenceKey.self, perform: closure)
    }

}

// MARK: - Rounded corners

#if canImport(UIKit)

extension View {

    @ViewBuilder
    func roundedCorner(
        _ radius: CGFloat,
        corners: UIRectCorner,
        edgesIgnoringSafeArea edges: Edge.Set = []
    ) -> some View {
        if radius > 0 {
            #if swift(>=5.9)
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                self.mask(
                    UnevenRoundedRectangle(radius: radius, corners: corners),
                    edgesIgnoringSafeArea: edges
                )
            } else {
                self.mask(
                    RoundedCorner(radius: radius, corners: corners),
                    edgesIgnoringSafeArea: edges
                )
            }
            #else
            self.mask(
                RoundedCorner(radius: radius, corners: corners),
                edgesIgnoringSafeArea: edges
            )
            #endif
        } else {
            self
        }
    }

    private func mask(_ shape: some Shape, edgesIgnoringSafeArea edges: Edge.Set) -> some View {
        self.mask(shape.edgesIgnoringSafeArea(edges))
    }

}

private struct RoundedCorner: Shape {

    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: self.corners,
                                cornerRadii: CGSize(width: self.radius, height: self.radius))
        return Path(path.cgPath)
    }

}

#endif

// MARK: - Disabling Refreshable

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Disables the refreshable action for a view.
    /// - Returns: A view with the refreshable action removed.
    ///
    /// This is useful when you want to disable the refreshable action for a view that may inherit it from its
    /// container.
    ///
    /// # Use case
    /// When a `PaywallView` is presented, the presenting view may have a refreshable action. If the `refreshable`
    /// modifier is applied **after** the modifier that presents the `PaywallView` (e.g. with `.sheet`), then the
    /// `PaywallView` will also inherit the refreshable action.
    /// ```swift
    /// contentView
    ///     .sheet(isPresented: $paywallPresented) {
    ///         PaywallView(offering: offering)
    ///     }
    ///     .refreshable {
    ///         // Some async code to refresh contentView
    ///     }
    /// ```
    ///
    /// `PaywallView` uses this `refreshableDisabled()` modifier to disable the inherited refreshable action, if any.
    @ViewBuilder
    func refreshableDisabled() -> some View {
        if let refreshKeyPath = \EnvironmentValues.refresh as? WritableKeyPath<EnvironmentValues, RefreshAction?> {
            self.environment(refreshKeyPath, nil)
        } else {
            self
        }
    }

}

// MARK: - Preference Keys

private protocol ViewDimensionPreferenceKey: PreferenceKey where Value == CGFloat {}

extension ViewDimensionPreferenceKey {

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let newValue = max(value, nextValue())
        if newValue != value {
            value = newValue
        }
    }

}

/// `PreferenceKey` for keeping track of a view width.
private struct ViewWidthPreferenceKey: ViewDimensionPreferenceKey {

    static var defaultValue: Value = 10

}

/// `PreferenceKey` for keeping track of a view height.
private struct ViewHeightPreferenceKey: ViewDimensionPreferenceKey {

    static var defaultValue: Value = 10

}

/// `PreferenceKey` for keeping track of view size.
private struct ViewSizePreferenceKey: PreferenceKey {

    typealias Value = CGSize

    static var defaultValue: Value = .init(width: 10, height: 10)

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }

}

// MARK: -

private extension Axis {

    var scrollViewAxis: Axis.Set {
        switch self {
        case .horizontal: return .horizontal
        case .vertical: return .vertical
        }
    }

}

// MARK: -

#if swift(>=5.9) && canImport(UIKit)
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private extension UnevenRoundedRectangle {

    /// Creates a `UnevenRoundedRectangle` rounding `corners` with  `radius`.
    /// - Note: this does not take RTL into account.
    init(radius: CGFloat, corners: UIRectCorner) {
        self.init(
            topLeadingRadius: corners.contains(.topLeft) ? radius : 0,
            bottomLeadingRadius: corners.contains(.bottomLeft) ? radius : 0,
            bottomTrailingRadius: corners.contains(.bottomRight) ? radius : 0,
            topTrailingRadius: corners.contains(.topRight) ? radius : 0,
            style: .continuous
        )
    }
}
#endif
