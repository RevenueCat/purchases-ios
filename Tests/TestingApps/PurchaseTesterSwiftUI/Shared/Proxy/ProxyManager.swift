//
//  ProxyManager.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 5/19/23.
//

import Foundation

enum ProxyStatus {

    enum Mode: String, Decodable, CaseIterable {

        case disabled               = "OFF"
        case serverDown             = "SERVER_DOWN"
        case overrideEntitlements   = "OVERRIDE_ENTITLEMENTS"

    }

    case disabled
    case enabled(Mode)

}

final class ProxyManager {

    static func fetchProxyStatus(proxyURL: URL) async -> ProxyStatus {
        do {
            let response: ProxyStatusResponse = try await URLSession.shared
                .fetch(proxyURL: proxyURL,
                       path: "status")

            return .enabled(response.mode)
        } catch {
            print("Error fetching proxy status: \(error.localizedDescription)")
            return .disabled
        }
    }

    /// Throws if mode failed to change
    static func changeMode(proxyURL: URL, to newMode: ProxyStatus.Mode) async throws {
        let _: ProxyChangeModeResponse = try await URLSession.shared
            .fetch(proxyURL: proxyURL, path: newMode.pathToChange)
    }

}

extension ProxyStatus.Mode: CustomStringConvertible {

    var description: String {
        switch self {
        case .disabled: return "Disabled"
        case .serverDown: return "Server down"
        case .overrideEntitlements: return "Fake entitlements"
        }
    }

    fileprivate var pathToChange: String {
        switch self {
        case .disabled: return "off"
        case .serverDown: return "server_down"
        case .overrideEntitlements: return "entitlements"
        }
    }

}

extension ProxyStatus: CustomStringConvertible {

    var description: String {
        switch self {
        case .disabled: return "Disabled"
        case let .enabled(mode): return "Running (\(mode.description))"
        }
    }

}

// MARK: -

private extension URLSession {

    func fetch<T: Decodable>(proxyURL: URL, path: String) async throws -> T {
        let (data, _) = try await self.data(from: URL(string: path, relativeTo: proxyURL)!)
        let decoder = JSONDecoder()

        return try decoder.decode(T.self, from: data)
    }

}

// MARK: - Responses

private struct ProxyStatusResponse: Decodable {

    let mode: ProxyStatus.Mode

}

private struct ProxyChangeModeResponse: Decodable {

    let result: String
    let mode: ProxyStatus.Mode

}
