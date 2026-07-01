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
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            do {
                return try Self.brotliDecompressedOnSupportedOS(bytes)
            } catch {
                throw RCContainer.Parser.FormatError.contentDecompressionFailed(Self.brotli.rawValue)
            }
        } else {
            throw RCContainer.Parser.FormatError.unsupportedContentEncoding(Self.brotli.rawValue)
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    static func brotliDecompressedOnSupportedOS(_ bytes: UnsafeRawBufferPointer) throws -> Data {
        var offset = 0
        let filter = try InputFilter(.decompress, using: .brotli) { requestedLength -> Data? in
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
    }

}
