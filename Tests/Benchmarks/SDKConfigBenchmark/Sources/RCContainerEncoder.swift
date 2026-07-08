import Foundation

/// Serializes RC-Container payloads for the fixture server, mirroring the wire format that
/// `RCContainer.Parser` reads: an 8-byte header followed by elements, each with a 24-byte
/// SHA-256-prefix checksum, little-endian wire size, encoding byte, 3 reserved bytes, the
/// payload, and zero padding to an 8-byte boundary. Only the `none` encoding is produced;
/// the benchmark measures transport and decode behavior, not compression codecs.
enum RCContainerEncoder {

    private static let version: UInt8 = 1
    private static let checksumSize = 24
    private static let paddingBoundary = 8

    /// Builds a container whose first element is the config payload followed by the given
    /// inline content elements, matching what `RemoteConfigContainer` expects.
    static func container(config: Data, contentElements: [Data]) -> Data {
        var data = Data([UInt8(ascii: "R"), UInt8(ascii: "C"), self.version, 0])
        data.append(contentsOf: [0, 0, 0, 0])

        for element in [config] + contentElements {
            self.appendElement(element, to: &data)
        }

        return data
    }

    /// The externally-referenced blob ref for a payload: SHA-256 truncated to 24 bytes,
    /// URL-safe base64 without padding (32 characters).
    static func blobRef(for data: Data) -> String {
        return self.checksum(for: data)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

}

private extension RCContainerEncoder {

    static func checksum(for data: Data) -> Data {
        return data.sha256.prefix(self.checksumSize)
    }

    static func appendElement(_ payload: Data, to data: inout Data) {
        data.append(self.checksum(for: payload))
        data.appendLittleEndianUInt32(UInt32(payload.count))
        data.append(0) // ContentEncoding.none
        data.append(contentsOf: [0, 0, 0])
        data.append(payload)

        let remainder = payload.count % self.paddingBoundary
        if remainder != 0 {
            data.append(Data(repeating: 0, count: self.paddingBoundary - remainder))
        }
    }

}

private extension Data {

    mutating func appendLittleEndianUInt32(_ value: UInt32) {
        self.append(UInt8(value & 0xff))
        self.append(UInt8((value >> 8) & 0xff))
        self.append(UInt8((value >> 16) & 0xff))
        self.append(UInt8((value >> 24) & 0xff))
    }

}
