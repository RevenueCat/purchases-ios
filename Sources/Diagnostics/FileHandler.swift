//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FileHandler.swift
//
//  Created by Nacho Soto on 6/16/23.

import Foundation

/// A wrapper that allows basic operations on a file, synchronized as an `actor`.
protocol FileHandlerType: Sendable {

    /// Returns an async sequence for every line in the file
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func readLines() async throws -> AsyncLineSequence<FileHandle.AsyncBytes>

    /// Adds a line at the end of the file
    func append(line: String) async

    /// Removes the contents of the file
    func emptyFile() async throws

    /// Deletes the first N lines from the file, without loading the entire file in memory.
    func removeFirstLines(_ count: Int) async throws

    func fileSizeInKB() async throws -> Double

}

actor FileHandler: FileHandlerType {

    private var fileHandle: FileHandle

    let url: URL

    init(_ fileURL: URL) throws {
        try Self.createFileIfNecessary(fileURL)

        self.url = fileURL
        self.fileHandle = try FileHandle(fileURL)
    }

    deinit {
        let url = self.url
        Logger.verbose(Message.closing_handle(url))

        self.fileHandle.closeAndLogErrors()
    }

    /// - Note: this loads the entire file in memory
    /// For newer versions, consider using `readLines` instead.
    func readFile() throws -> Data {
        RCTestAssertNotMainThread()

        try self.moveToBeginningOfFile()

        return self.fileHandle.availableData
    }

    /// Returns an async sequence for every line in the file
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func readLines() throws -> AsyncLineSequence<FileHandle.AsyncBytes> {
        RCTestAssertNotMainThread()

        try self.moveToBeginningOfFile()

        return self.fileHandle.bytes.lines
    }

    /// Adds a line at the end of the file
    func append(line: String) {
        RCTestAssertNotMainThread()

        self.fileHandle.seekToEndOfFile()
        self.fileHandle.write(line.asData)
        self.fileHandle.write(Self.lineBreakData)
    }

    /// Removes the contents of the file
    func emptyFile() async throws {
        RCTestAssertNotMainThread()

        do {
            try self.fileHandle.truncate(atOffset: 0)
            try self.fileHandle.synchronize()
        } catch {
            throw Error.failedEmptyingFile(error)
        }
    }

    /// Deletes the first N lines from the file, without loading the entire file in memory.
    func removeFirstLines(_ count: Int) async throws {
        precondition(count > 0, "Invalid count: \(count)")

        try self.moveToBeginningOfFile()

        // Create a handle to write the new contents
        let tempURL = try Self.createTemporaryFile()
        let outputFile = try FileHandle(tempURL)

        var linesDetected = 0

        repeat {
            // Read N bytes at a time
            let data = self.fileHandle.readData(ofLength: Self.bufferSize)

            guard !data.isEmpty, let string = String(data: data, encoding: .utf8) else {
                break
            }

            // After detecting `count` lines, start writing
            linesDetected += string.countOccurences(of: Self.lineBreak)
            if linesDetected >= count {
                let linesToWrite = string
                    .components(separatedBy: String(Self.lineBreak))
                    .suffix(linesDetected - count + 1)
                    .joined(separator: String(Self.lineBreak))

                outputFile.write(linesToWrite.asData)
            }
        } while true

        // Replace with temporary file
        try self.replaceHandler(with: tempURL)
    }

    func fileSizeInKB() async throws -> Double {
        let attributes = try FileManager.default.attributesOfItem(atPath: self.url.path)
        guard let fileSizeInBytes = attributes[.size] as? NSNumber else {
            throw Error.failedGettingFileSize(self.url)
        }
        return Double(fileSizeInBytes.intValue) / 1024
    }

    // MARK: -

    private static let fileManager: FileManager = .default

    private static let lineBreak: Character = "\n"
    private static let lineBreakData = String(FileHandler.lineBreak).asData
    private static let bufferSize = 4096

}

// MARK: - Errors

extension FileHandler {

    enum Error: Swift.Error {

        case failedCreatingFile(URL)
        case failedCreatingDirectory(URL)
        case failedCreatingHandle(Swift.Error)
        case failedSeeking(Swift.Error)
        case failedEmptyingFile(Swift.Error)
        case failedMovingNewFile(from: URL, toURL: URL, Swift.Error)
        case failedGettingFileSize(URL)

    }

}

// MARK: - Private

private extension FileHandler {

    func moveToBeginningOfFile() throws {
        do {
            try self.fileHandle.seek(toOffset: 0)
        } catch {
            throw Error.failedSeeking(error)
        }
    }

    static func createFileIfNecessary(_ url: URL) throws {
        guard !Self.fileManager.fileExists(atPath: url.path) else { return }

        let directoryURL = url.deletingLastPathComponent()
        if !Self.fileManager.fileExists(atPath: directoryURL.path) {
            do {
                Logger.verbose(Message.creating_directory(directoryURL))

                try Self.fileManager.createDirectory(at: directoryURL,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
            } catch {
                throw Error.failedCreatingDirectory(directoryURL)
            }
        }

        Logger.verbose(Message.creating_file(url))

        if !Self.fileManager.createFile(atPath: url.path, contents: nil, attributes: nil) {
            throw Error.failedCreatingFile(url)
        }
    }

    static func createTemporaryFile() throws -> URL {
        let result = Self.fileManager.temporaryDirectory
            .appendingPathComponent("com.revenenuecat")
            .appendingPathComponent(UUID().uuidString)

        try Self.createFileIfNecessary(result)
        return result
    }

    func replaceHandler(with otherURL: URL) throws {
        do {
            try Self.fileManager.removeItem(at: self.url)
            try Self.fileManager.moveItem(at: otherURL, to: self.url)
        } catch {
            throw Error.failedMovingNewFile(from: otherURL, toURL: self.url, error)
        }

        self.fileHandle.closeAndLogErrors()
        self.fileHandle = try .init(self.url)
    }

}

private extension FileHandle {

    convenience init(_ url: URL) throws {
        do {
            Logger.verbose(Message.creating_handler(url))
            try self.init(forUpdating: url)
        } catch {
            Logger.warn(Message.failed_creating_handle(error))
            throw FileHandler.Error.failedCreatingHandle(error)
        }
    }

    func closeAndLogErrors() {
        do {
            try self.close()
        } catch {
            Logger.warn(Message.failed_closing_handle(error))
        }
    }

}

// MARK: - Messages

// swiftlint:disable identifier_name

private enum Message: LogMessage {

    case creating_handler(URL)
    case closing_handle(URL)
    case failed_creating_handle(Error)
    case failed_closing_handle(Error)

    case creating_directory(URL)
    case creating_file(URL)

    var description: String {
        switch self {
        case let .creating_handler(url):
            return "Creating FileHandler for: \(url)"

        case let .closing_handle(url):
            return "Closing FileHandler for: \(url)"

        case let .failed_creating_handle(error):
            return "Error creating FileHandle: \(error.localizedDescription)"

        case let .failed_closing_handle(error):
            return "Error closing FileHandle: \(error.localizedDescription)"

        case let .creating_directory(url):
            return "Creating directory: \(url)"

        case let .creating_file(url):
            return "Creating file: \(url)"
        }
    }

    var category: String { return "file_handler" }

}

// swiftlint:enable identifier_name
