//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallFontFetcherType.swift
//
//  Created by Facundo Menzella on 30/5/25.

import CoreText
import Foundation

protocol FontRegistrar {
    func registerFont(at url: URL) throws
}

struct SystemFontRegistry: FontRegistrar {

    func registerFont(at url: URL) throws {
        var errorRef: Unmanaged<CFError>?

        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef) {
            throw errorRef?.takeUnretainedValue() ?? DefaultPaywallFontsFetcher.UnknownError()
        }
    }
}

protocol FileManaging {
    func fileExists(atPath path: String) -> Bool
    func copyItem(at srcURL: URL, to dstURL: URL) throws
}

extension FileManager: FileManaging {}

protocol FontDownloadSession {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: FontDownloadSession {}

actor DefaultPaywallFontsFetcher: PaywallFontFetcherType {

    struct UnknownError: Error { }

    private let fileManager: FileManaging
    private let session: FontDownloadSession
    private let registrar: FontRegistrar
    private let tempDirectory: URL

    init(
        fileManager: FileManaging = FileManager.default,
        session: FontDownloadSession = URLSession.shared,
        registrar: FontRegistrar = SystemFontRegistry(),
        tempDirectory: URL = FileManager.default.temporaryDirectory
    ) {
        self.fileManager = fileManager
        self.session = session
        self.registrar = registrar
        self.tempDirectory = tempDirectory
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func downloadFont(from url: URL, familyName: String) async throws {
        _ = try await session.data(from: url)

        let destination = tempDirectory.appendingPathComponent(familyName)

        // WIP: Use the name to verify if it exists
        let families = CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? []
        if families.contains(familyName) {
            return
        }

        // already downloaded
        if fileManager.fileExists(atPath: destination.path) {
            return
        }

        try fileManager.copyItem(at: url, to: destination)

        try registrar.registerFont(at: destination)
    }
}
