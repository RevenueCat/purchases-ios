//
//  RCContainer+Compression.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 29/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Compression
import Foundation
import zlib

extension RCContainer.Element.ContentEncoding {

    /// Provides decoded bytes for this content encoding.
    ///
    /// `.none` borrows the original wire bytes without copying. Compressed encodings allocate a
    /// temporary decoded buffer because decompression necessarily materializes new bytes.
    func withDecodedBytes<T>(
        from bytes: UnsafeRawBufferPointer,
        _ body: (UnsafeRawBufferPointer) throws -> T
    ) throws -> T {
        switch self {
        case .none:
            return try body(bytes)
        case .gzip:
            let decoded = try Self.gzipDecompressed(bytes)
            return try decoded.withUnsafeBytes(body)
        case .brotli:
            let decoded = try Self.brotliDecompressed(bytes)
            return try decoded.withUnsafeBytes(body)
        case .zstd, .unsupported:
            throw RCContainer.Parser.FormatError.unsupportedContentEncoding(self.rawValue)
        }
    }

    /// The Compression algorithm used to decode brotli payloads, or `nil` when the running OS
    /// doesn't provide brotli.
    ///
    /// We deliberately avoid referencing `Compression.Algorithm.brotli` directly. The SDK declares
    /// the whole `Algorithm` enum (including `.brotli`) as available since iOS 13 without a per-case
    /// availability annotation, so the compiler strong-links the `.brotli` symbol. That symbol only
    /// exists in the runtime starting on iOS 16 / macOS 13 / tvOS 16 / watchOS 9, so referencing the
    /// case crashes at load time (`dlopen` "Symbol not found") on earlier runtimes such as an iOS 15
    /// simulator. Building the algorithm from the `COMPRESSION_BROTLI` C constant emits no such
    /// symbol and doubles as a runtime capability check: the initializer returns `nil` when the
    /// running OS doesn't recognize brotli.
    static var brotliAlgorithm: Algorithm? {
        return Algorithm(rawValue: COMPRESSION_BROTLI)
    }

}

private extension RCContainer.Element.ContentEncoding {

    static let gzipWindowBits = MAX_WBITS + 16
    static let outputChunkSize = 64 * 1024

    static func gzipDecompressed(_ bytes: UnsafeRawBufferPointer) throws -> Data {
        var stream = z_stream()
        let streamSize = Int32(MemoryLayout<z_stream>.size)
        guard inflateInit2_(&stream, Self.gzipWindowBits, ZLIB_VERSION, streamSize) == Z_OK else {
            throw RCContainer.Parser.FormatError.contentDecompressionFailed(Self.gzip.rawValue)
        }
        defer { inflateEnd(&stream) }

        stream.next_in = UnsafeMutablePointer<Bytef>(
            mutating: bytes.bindMemory(to: Bytef.self).baseAddress
        )
        stream.avail_in = uInt(bytes.count)

        var output = Data()
        var status: Int32 = Z_OK
        repeat {
            var chunk = [UInt8](repeating: 0, count: Self.outputChunkSize)
            try chunk.withUnsafeMutableBytes { outputBytes in
                stream.next_out = outputBytes.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(outputBytes.count)

                status = inflate(&stream, Z_NO_FLUSH)
                guard status == Z_OK || status == Z_STREAM_END else {
                    throw RCContainer.Parser.FormatError.contentDecompressionFailed(Self.gzip.rawValue)
                }

                let byteCount = outputBytes.count - Int(stream.avail_out)
                output.append(contentsOf: outputBytes.prefix(byteCount))
            }
        } while status != Z_STREAM_END

        guard stream.avail_in == 0 else {
            throw RCContainer.Parser.FormatError.contentDecompressionFailed(Self.gzip.rawValue)
        }

        return output
    }

    static func brotliDecompressed(_ bytes: UnsafeRawBufferPointer) throws -> Data {
        // See `brotliAlgorithm` for why we probe availability this way instead of using `.brotli`.
        guard let algorithm = Self.brotliAlgorithm else {
            throw RCContainer.Parser.FormatError.unsupportedContentEncoding(Self.brotli.rawValue)
        }

        do {
            var offset = 0
            let filter = try InputFilter(.decompress, using: algorithm) { requestedLength -> Data? in
                guard offset < bytes.count else { return nil }

                let endOffset = min(offset + requestedLength, bytes.count)
                let chunk = bytes[offset..<endOffset]
                offset = endOffset
                return Data(chunk)
            }

            var output = Data()
            while let chunk = try filter.readData(ofLength: Self.outputChunkSize) {
                output.append(chunk)
            }

            return output
        } catch {
            throw RCContainer.Parser.FormatError.contentDecompressionFailed(Self.brotli.rawValue)
        }
    }

}
