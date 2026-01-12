//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CacheStrings.swift
//
//  Created by Rick van der Linden on 12/01/2026.

import Foundation

// swiftlint:disable identifier_name
enum CacheStrings {

    case cache_url_not_available
    case failed_to_save_codable_to_cache(Error)
    case failed_to_delete_old_cache_directory(Error)

}

extension CacheStrings: LogMessage {
    var description: String {
        switch self {
        case .cache_url_not_available:
            return "Cache URL is not available"
        case .failed_to_save_codable_to_cache(let error):
            return "Failed to save codable to cache: \(error)"
        case .failed_to_delete_old_cache_directory(let error):
            return "Failed to delete old cache directory: \(error)"
        }
    }

    var category: String { return "cache" }
}
