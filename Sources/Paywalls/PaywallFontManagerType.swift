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
            throw DefaultPaywallFontsManager.FontsManagerError.registrationError(errorRef?.takeUnretainedValue())
        }
    }
}

protocol FontsFileManaging {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(at url: URL) throws
    func write(_ data: Data, to url: URL) throws
    func cachesDirectory() throws -> URL
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

    func cachesDirectory() throws -> URL {
        guard let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return url
    }
}

protocol FontDownloadSession {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: FontDownloadSession {}

actor DefaultPaywallFontsManager: PaywallFontManagerType {

    enum FontsManagerError: Error {
        case registrationError(Error?)
        case hashValidationError(expected: String, actual: String)
    }

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

    func installFont(from remoteURL: URL, hash: String) async throws {
        let destination = try self.fileURLForFontAtRemoteURL(remoteURL)

        if !fileManager.fileExists(atPath: destination.path) {
            let (data, _) = try await session.data(from: remoteURL)
            let dataHash = data.md5String
            guard dataHash == hash else {
                throw FontsManagerError.hashValidationError(expected: hash, actual: dataHash)
            }

            try fileManager.write(data, to: destination)
        }

        try registrar.registerFont(at: destination)
    }

    // MARK: - Private

    private func fontsDirectory() throws -> URL {
        let fontsDirectory = try fileManager
            .cachesDirectory()
            .appendingPathComponent("RevenueCatFonts", isDirectory: true)
        try fileManager.createDirectory(at: fontsDirectory)
        return fontsDirectory
    }

    private func fileURLForFontAtRemoteURL(_ remoteURL: URL) throws -> URL {
        let fontsDirectory = try fontsDirectory()
        let fileName = Data(remoteURL.absoluteString.utf8).md5String + remoteURL.pathExtension
        return fontsDirectory.appendingPathComponent(fileName, isDirectory: false)
    }

}

extension DefaultPaywallFontsManager.FontsManagerError: CustomStringConvertible {

    var description: String {
        switch self {
        case let .registrationError(error):
            return "Font registration error: \(error?.localizedDescription ?? "Unknown error")"
        case let .hashValidationError(expected, actual):
            return "Font hash validation failed. Expected: \(expected), Actual: \(actual)"
        }
    }
}
