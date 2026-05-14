//
//  RulesEngine.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Namespace for the RevenueCat rules engine.
///
/// This module is an implementation detail of the RevenueCat SDK. Every
/// declaration in this framework is exposed under the `Internal` SPI
/// (`@_spi(Internal)`) so it can be consumed by `RevenueCat` and/or
/// `RevenueCatUI` without becoming part of the SDK's public API. Add
/// `@_spi(Internal)` to every new public declaration in this module.
@_spi(Internal) public enum RulesEngine {}
