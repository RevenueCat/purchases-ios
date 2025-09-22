//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SizeModifier.swift
//
//  Created by Jacob Zivan Rakidzich on 9/22/25.
//

import Foundation
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct SizeReader: View {
    @Binding var size: CGSize

    var body: some View {
        Spacer()
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizeKey.self, value: proxy.size)
                }
            }
        .onPreferenceChange(SizeKey.self) { preferences in
            self.size = preferences
        }
    }
}

private struct SizeKey: PreferenceKey {
    typealias Value = CGSize

    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        _ = nextValue()
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func sizeReader(_ size: Binding<CGSize>) -> some View {
        ZStack {
            SizeReader(size: size)
            self
        }
    }
}
