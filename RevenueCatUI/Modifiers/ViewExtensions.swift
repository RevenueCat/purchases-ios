//
//  ViewExtensions.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
import SwiftUI

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension View {

    @ViewBuilder
    func hidden(if condition: Bool) -> some View {
        if condition {
            self.hidden()
        } else {
            self
        }
    }

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
        if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
            self.scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @ViewBuilder
    func scrollableIfNecessary(_ axes: Axis.Set = .vertical) -> some View {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            ViewThatFits(in: axes) {
                self

                ScrollView(axes) {
                    self
                }
            }
        } else {
            ScrollView(axes) {
                self
            }
        }
    }

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

    /// Invokes the given closure with the dimension specified by `axis` changes whenever it changes.
    func onSizeChange(
        _ axis: Axis,
        _ closure: @escaping (CGFloat) -> Void
    ) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ViewDimensionPreferenceKey.self,
                            value: axis == .horizontal
                                ? geometry.size.width
                                : geometry.size.height
                        )
                }
            )
            .onPreferenceChange(ViewDimensionPreferenceKey.self, perform: closure)
    }

}

// MARK: - Preference Keys

/// `PreferenceKey` for keeping track of a view dimension.
private struct ViewDimensionPreferenceKey: PreferenceKey {

    typealias Value = CGFloat

    static var defaultValue: Value = 10

    static func reduce(value: inout Value, nextValue: () -> Value) {
        let newValue = max(value, nextValue())
        if newValue != value {
            value = newValue
        }
    }

}

/// `PreferenceKey` for keeping track of view size.
private struct ViewSizePreferenceKey: PreferenceKey {

    typealias Value = CGSize

    static var defaultValue: Value = .init(width: 10, height: 10)

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }

}
