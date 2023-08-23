//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Constants.swift
//
//  Created by Nacho Soto on 7/13/23.

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
enum Constants {

    static let defaultAnimation: Animation = .easeInOut(duration: 0.2)
    static let fastAnimation: Animation = .easeInOut(duration: 0.1)
    static let toggleAllPlansAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.7)

    static let defaultCornerRadius: CGFloat = 20

    /// For UI elements that wouldn't make sense to keep scaling up forever
    static let maximumDynamicTypeSize: DynamicTypeSize = .accessibility3

    static let defaultHorizontalPadding: CGFloat? = VersionDetector.isIpad ? 24 : nil
    static let defaultVerticalPadding: CGFloat? = VersionDetector.isIpad ? 16 : nil

}
