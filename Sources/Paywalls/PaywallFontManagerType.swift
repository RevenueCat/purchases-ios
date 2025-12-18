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
#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

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
        case invalidResponse
        case downloadError(HTTPStatusCode)
        case registrationError(Error?)
        case hashValidationError(expected: String, actual: String)
    }

    private let fontsDirectory: URL?
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
        do {
            self.fontsDirectory = try DefaultPaywallFontsManager.fontsDirectory(fileManager: fileManager)
        } catch {
            Logger.error(Strings.paywalls.error_creating_fonts_directory(error))
            self.fontsDirectory = nil
        }
    }

    nonisolated func fontIsAlreadyInstalled(fontName: String, fontFamily: String?) -> Bool {
        var availableFontNames: [String] = []
        #if canImport(UIKit)
        if let fontFamily = fontFamily {
            availableFontNames = UIFont.fontNames(forFamilyName: fontFamily)
        } else {
            availableFontNames = UIFont.familyNames.flatMap {
                UIFont.fontNames(forFamilyName: $0)
            }
        }
        #elseif canImport(AppKit)
        availableFontNames = NSFontManager.shared.availableFonts
        #endif

        return availableFontNames.contains(fontName)
    }

    func installFont(_ font: DownloadableFont) async throws {
        let remoteURL = font.url
        guard let destination = self.fileURLForFontAtRemoteURL(remoteURL) else {
            return
        }

        if !fileManager.fileExists(atPath: destination.path) {
            Logger.verbose(Strings.paywalls.triggering_font_download(fontURL: remoteURL))
            let (data, urlResponse) = try await session.data(from: remoteURL)

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw FontsManagerError.invalidResponse
            }

            let httpStatusCode = HTTPStatusCode(rawValue: httpResponse.statusCode)
            guard httpStatusCode.isSuccessfulResponse else {
                throw FontsManagerError.downloadError(httpStatusCode)
            }

            let expectedHash = font.hash
            let actualHash = data.md5String
            guard actualHash == expectedHash else {
                throw FontsManagerError.hashValidationError(expected: expectedHash, actual: actualHash)
            }

            try fileManager.write(data, to: destination)
            Logger.debug(Strings.paywalls.font_downloaded_sucessfully(name: font.name, fontURL: remoteURL))
        }

        try registrar.registerFont(at: destination)
    }

    // MARK: - Private

    private static func fontsDirectory(fileManager: FontsFileManaging) throws -> URL {
        let fontsDirectory = try fileManager
            .cachesDirectory()
            .appendingPathComponent("RevenueCatFonts", isDirectory: true)
        try fileManager.createDirectory(at: fontsDirectory)
        return fontsDirectory
    }

    private func fileURLForFontAtRemoteURL(_ remoteURL: URL) -> URL? {
        guard let fontsDirectory = self.fontsDirectory else {
            return nil
        }
        let fileName = Data(remoteURL.absoluteString.utf8).md5String + "." + remoteURL.pathExtension
        return fontsDirectory.appendingPathComponent(fileName, isDirectory: false)
    }

}

extension DefaultPaywallFontsManager.FontsManagerError: CustomStringConvertible {

    var description: String {
        switch self {
        case .invalidResponse:
            return "Font download failed with an invalid response"
        case .downloadError(let statusCode):
            return "Font download failed with status code: \(statusCode.rawValue)"
        case let .registrationError(error):
            return "Font registration error: \(error?.localizedDescription ?? "Unknown error")"
        case let .hashValidationError(expected, actual):
            return "Downloaded font file is corrupt. Hash mismatch. Expected: \(expected), Actual: \(actual)"
        }
    }
}
