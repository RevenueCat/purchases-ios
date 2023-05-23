//
//  ProxyView.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 5/19/23.
//

import Foundation
import SwiftUI

struct ProxyView: View {

    @StateObject
    private var viewModel: ProxyViewModel = .init()
    @State
    private var changingMode: Bool = false

    let proxyURL: URL?

    var body: some View {
        if let proxyURL {
            VStack {
                Text(verbatim: "\(self.viewModel.proxyStatus?.description ?? "loading...")")
                    .task(id: proxyURL) {
                        await self.viewModel.refreshStatus(proxyURL: proxyURL)
                    }


                HStack(spacing: 5) {
                    ForEach(ProxyStatus.Mode.allCases, id: \.self) { mode in
                        self.modeButton(mode, proxyURL: proxyURL)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func modeButton(_ mode: ProxyStatus.Mode, proxyURL: URL) -> some View {
        Button {
            self.changingMode = true

            Task<Void, Never> {
                await self.viewModel.changeMode(to: mode, proxyURL: proxyURL)

                self.changingMode = false
            }
        } label: {
            Text(mode.description)
        }
        .buttonStyle(.borderedProminent)
        .disabled(self.changingMode)
    }

}
