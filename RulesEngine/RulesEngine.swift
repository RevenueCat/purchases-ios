//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RulesEngine.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Namespace for the RevenueCat rules engine. Named `Rules` rather than
/// `RulesEngine` to avoid colliding with the module name — from the test
/// target's perspective (`@testable import RulesEngine`) the bare
/// identifier `RulesEngine` resolves to the module, which would force
/// callers to write `RulesEngine.RulesEngine.something` to reach the
/// namespace.
@_spi(Internal) public enum Rules {}
