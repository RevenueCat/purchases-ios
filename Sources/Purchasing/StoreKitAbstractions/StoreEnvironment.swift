//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreEnvironment.swift
//
//  Created by MarkVillacampa on 26/10/23.
//

import Foundation
import StoreKit

/// A wrapper for `StoreKit.AppStore.Environment`.
enum StoreEnvironment: String {

    case production
    case sandbox
    case xcode

}

extension StoreEnvironment: Equatable, Codable {}

// MARK: - Private

extension StoreEnvironment {

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    init?(environment: StoreKit.AppStore.Environment) {
        switch environment {
        case .production:
            self = .production
        case .sandbox:
            self = .sandbox
        case .xcode:
            self = .xcode
        default:
            Logger.appleWarning(Strings.storeKit.sk2_unknown_environment(environment.rawValue))
            return nil
        }
    }

    init?(environment: String) {
        switch environment {
        case "Production":
            self = .production
        case "Sandbox":
            self = .sandbox
        case "Xcode":
            self = .xcode
        default:
            Logger.appleWarning(Strings.storeKit.sk2_unknown_environment(environment))
            return nil
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    init?(sk2Transaction: SK2Transaction) {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            self.init(environment: sk2Transaction.environment)
        } else {
            #if VISION_OS
            self.init(environment: sk2Transaction.environment)
            #else
            self.init(
                environment: sk2Transaction.environmentStringRepresentation
            )
            #endif
        }
    }

}
