//
//  Constants.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
enum Constants {

    static let defaultAnimation: Animation = .easeIn(duration: 0.2)
    static let fastAnimation: Animation = .easeIn(duration: 0.1)

    /// For UI elements that wouldn't make sense to keep scaling up forever
    static let maximumDynamicTypeSize: DynamicTypeSize = .accessibility3

}
