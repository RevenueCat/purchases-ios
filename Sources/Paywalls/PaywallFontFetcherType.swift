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

        // WIP: Check if already registered??

        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef) {
            throw errorRef?.takeUnretainedValue() ?? DefaultPaywallFontsFetcher.UnknownError()
        }
    }
}

protocol FontsFileManaging {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(at url: URL) throws
    func write(_ data: Data, to url: URL) throws
    func applicationSupportDirectory() throws -> URL
}

struct DefaultFontFileManager: FontsFileManaging {
    private let fileManager = FileManager.default

    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }

    func applicationSupportDirectory() throws -> URL {
        guard let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return url
    }
}

protocol FontDownloadSession {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: FontDownloadSession {}

actor DefaultPaywallFontsFetcher: PaywallFontFetcherType {

    struct UnknownError: Error { }

    private let fileManager: FontsFileManaging
    private let session: FontDownloadSession
    private let registrar: FontRegistrar

    init(
        fileManager: FontsFileManaging = DefaultFontFileManager(),
        session: FontDownloadSession = URLSession.shared,
        registrar: FontRegistrar = SystemFontRegistry()
    ) {
        self.fileManager = fileManager
        self.session = session
        self.registrar = registrar
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func downloadFont(from url: URL, hash: String) async throws {
        let fontsDirectory = try fileManager
            .applicationSupportDirectory()
            .appendingPathComponent("RevenueCatFonts", isDirectory: true)

        try fileManager.createDirectory(at: fontsDirectory)

        let destination = fontsDirectory.appendingPathComponent(hash)

        if !fileManager.fileExists(atPath: destination.path) {
            let (data, _) = try await session.data(from: url)
            try fileManager.write(data, to: destination)
        }

        try registrar.registerFont(at: destination)
    }
}
