//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RawDataContainer.swift
//
//  Created by Nacho Soto on 11/16/21.

/// A type which exposes its underlying raw data, for debugging purposes or for getting access
/// to future data while using an older version of the SDK.
public protocol RawDataContainer {

    /// The type of the underlying raw data
    associatedtype Content

    /// The underlying data.
    var rawData: Content { get }

}
