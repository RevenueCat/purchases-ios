//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FileRepositoryStrings.swift
//
//  Created by Jacob Zivan Rakidzich on 8/14/25.

import Foundation

enum FileRepositoryStrings {

    case failedToSaveCachedFile(URL, Error)
    case failedToFetchFileFromRemoteSource(URL, Error)
    case failedToCreateCacheDirectory(URL)
    case failedToCreateDocumentDirectory(URL)
    case failedToCreateTemporaryFile(URL)

}

extension FileRepositoryStrings: LogMessage {
    var description: String {
        switch self {
        case .failedToSaveCachedFile(let url, let error):
            return "Failed to save file to \(url.absoluteString): \(error)"
        case .failedToFetchFileFromRemoteSource(let url, let error):
            return "Failed to download file from \(url.absoluteString): \(error)"
        case .failedToCreateCacheDirectory(let url):
            return "Failed to create cache directory for \(url.absoluteString)"
        case .failedToCreateDocumentDirectory(let url):
            return "Failed to create Document directory for \(url.absoluteString)"
        case .failedToCreateTemporaryFile(let url):
            return "Failed to create a temporary file for \(url.absoluteString)"
        }
    }

    var category: String { return "file_repository" }
}
