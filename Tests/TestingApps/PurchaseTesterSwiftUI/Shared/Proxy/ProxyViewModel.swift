//
//  ProxyViewModel.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 5/19/23.
//

import Foundation

@MainActor
final class ProxyViewModel: NSObject, ObservableObject {

    @Published var proxyStatus: ProxyStatus?

    override init() {}

    func refreshStatus(proxyURL: URL) async {
        self.proxyStatus = await ProxyManager.fetchProxyStatus(proxyURL: proxyURL)
    }

    func changeMode(to newMode: ProxyStatus.Mode, proxyURL: URL) async {
        do {
            try await ProxyManager.changeMode(proxyURL: proxyURL, to: newMode)
            self.proxyStatus = .enabled(newMode)
        } catch {
            print("Failed changing mode: \(error.localizedDescription)")
        }
    }

}
