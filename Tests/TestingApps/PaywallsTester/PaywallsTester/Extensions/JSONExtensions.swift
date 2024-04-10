//
//  JSONExtensions.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

public extension Encodable {

    /// - Throws: if encoding failed
    /// - Returns: `nil` if the encoded `Data` can't be serialized into a `String`.
    var encodedJSON: String? {
        get throws {
            return String(data: try self.jsonEncodedData, encoding: .utf8)
        }
    }

    /// - Note: beginning with iOS 17, the output of this is not guaranteed to be consistent due to key ordering.
    /// For tests, it's better to compare `prettyPrintedData` which does sort keys.
    var jsonEncodedData: Data {
        get throws {
            return try JSONEncoder.default.encode(self)
        }
    }

}

public extension Decodable {

    static func decodeJSON(
        _ data: [AnyHashable: Any]
    ) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: data, options: [])
        return try JSONDecoder.default.decode(self, from: data)
    }

}

public extension JSONDecoder {

    static let `default`: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = dateDecoding

        return decoder
    }()

}

// MARK: - Private

private extension JSONEncoder {

    static let `default`: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .secondsSince1970

        return encoder
    }()

    static let prettyPrinted: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]

        return encoder
    }()

}

private let dateDecoding: JSONDecoder.DateDecodingStrategy = .custom { decoder in
    var container = try decoder.singleValueContainer()

    if let milliseconds = try? container.decode(UInt64.self), milliseconds > 1000000000000 {
        return Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    } else if let seconds = try? container.decode(Double.self) {
        return Date(timeIntervalSince1970: seconds)
    } else {
        let dateString = try container.decode(String.self)

        guard let result = ISO8601DateFormatter().date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from '\(dateString)'"
            )
        }

        return result
    }
}
