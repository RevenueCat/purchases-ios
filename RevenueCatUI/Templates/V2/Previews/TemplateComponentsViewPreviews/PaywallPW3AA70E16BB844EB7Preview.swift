//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPW3AA70E16BB844EB7Preview.swift
//
//  Created by Codex on 4/10/26.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

#if DEBUG

private enum PaywallPW3AA70E16BB844EB7Preview {

    static let safeAreaInsets = EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)

    static let annualPackage = Package(
        identifier: "$rc_annual",
        packageType: .annual,
        storeProduct: .init(
            sk1Product: PreviewMock.Product(
                price: 7.99,
                unit: .year,
                localizedTitle: "Pro Annual"
            )
        ),
        offeringIdentifier: "perplexity_cesar_2",
        webCheckoutUrl: nil
    )

    static let offering = Offering(
        identifier: "perplexity_cesar_2",
        serverDescription: "",
        availablePackages: [Self.annualPackage],
        webCheckoutUrl: nil
    )

    static let paywallComponents = Offering.PaywallComponents(
        uiConfig: PreviewUIConfig.make(),
        data: .init(
            id: "pw3aa70e16bb844eb7",
            templateName: "components",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: Self.decodeBase64(Self.stackBase64),
                header: Self.decodeBase64(Self.headerBase64),
                stickyFooter: Self.decodeBase64(Self.stickyFooterBase64),
                background: Self.decodeBase64(Self.backgroundBase64)
            )),
            componentsLocalizations: [
                "en_US": Self.decodeBase64(Self.localizationsBase64)
            ],
            revision: 89,
            defaultLocaleIdentifier: "en_US"
        )
    )

    static func decodeBase64<T: Decodable>(_ base64: String) -> T {
        guard let data = Data(base64Encoded: base64) else {
            fatalError("Invalid base64 preview payload for pw3aa70e16bb844eb7")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            fatalError("Invalid preview JSON for pw3aa70e16bb844eb7: \(error)")
        }
    }

    static let backgroundBase64 = [
        "eyJ0eXBlIjoiY29sb3IiLCJ2YWx1ZSI6eyJsaWdodCI6eyJkZWdyZWVzIjo5MCwicG9pbnRzIjpbeyJjb2xvciI6IiNmZmZmZmZm",
        "ZiIsInBlcmNlbnQiOjB9LHsiY29sb3IiOiIjZmZmZmZmZmYiLCJwZXJjZW50Ijo3OX0seyJjb2xvciI6IiNmMGY0ZmZmZiIsInBl",
        "cmNlbnQiOjEwMH1dLCJ0eXBlIjoibGluZWFyIn19fQo="
    ].joined()

    static let headerBase64 = [
        "eyJmYWxsYmFjayI6eyJiYWNrZ3JvdW5kIjpudWxsLCJiYWNrZ3JvdW5kX2NvbG9yIjpudWxsLCJiYWRnZSI6bnVsbCwiYm9yZGVy",
        "IjpudWxsLCJjb21wb25lbnRzIjpbeyJiYWNrZ3JvdW5kX2NvbG9yIjpudWxsLCJjb2xvciI6eyJsaWdodCI6eyJ0eXBlIjoiaGV4",
        "IiwidmFsdWUiOiIjRkYwMTAxRkYifX0sImZvbnRfbmFtZSI6bnVsbCwiZm9udF9zaXplIjoxNCwiZm9udF93ZWlnaHQiOiJyZWd1",
        "bGFyIiwiZm9udF93ZWlnaHRfaW50Ijo0MDAsImhvcml6b250YWxfYWxpZ25tZW50IjoibGVhZGluZyIsImlkIjoiOFZHRDNoM1ZD",
        "YiIsIm1hcmdpbiI6eyJib3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJuYW1lIjoiIiwicGFkZGlu",
        "ZyI6eyJib3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJzaXplIjp7ImhlaWdodCI6eyJ0eXBlIjoi",
        "Zml0IiwidmFsdWUiOm51bGx9LCJ3aWR0aCI6eyJ0eXBlIjoiZml0IiwidmFsdWUiOm51bGx9fSwidGV4dF9saWQiOiJRZW40R1Nm",
        "MmxXIiwidHlwZSI6InRleHQifV0sImRpbWVuc2lvbiI6eyJhbGlnbm1lbnQiOiJsZWFkaW5nIiwiZGlzdHJpYnV0aW9uIjoic3Rh",
        "cnQiLCJ0eXBlIjoidmVydGljYWwifSwiaWQiOiJKbGhBT0s3SUUzIiwibWFyZ2luIjp7ImJvdHRvbSI6MCwibGVhZGluZyI6MCwi",
        "dG9wIjowLCJ0cmFpbGluZyI6MH0sIm5hbWUiOiJIZWFkZXIiLCJwYWRkaW5nIjp7ImJvdHRvbSI6MCwibGVhZGluZyI6MCwidG9w",
        "IjowLCJ0cmFpbGluZyI6MH0sInNoYWRvdyI6eyJjb2xvciI6eyJsaWdodCI6eyJ0eXBlIjoiaGV4IiwidmFsdWUiOiIjMDAwMDAw",
        "MzMifX0sInJhZGl1cyI6MTYsIngiOjAsInkiOjR9LCJzaGFwZSI6eyJjb3JuZXJzIjp7ImJvdHRvbV9sZWFkaW5nIjowLCJib3R0",
        "b21fdHJhaWxpbmciOjAsInRvcF9sZWFkaW5nIjowLCJ0b3BfdHJhaWxpbmciOjB9LCJ0eXBlIjoicmVjdGFuZ2xlIn0sInNpemUi",
        "OnsiaGVpZ2h0Ijp7InR5cGUiOiJmaXQiLCJ2YWx1ZSI6bnVsbH0sIndpZHRoIjp7InR5cGUiOiJmaWxsIiwidmFsdWUiOm51bGx9",
        "fSwic3BhY2luZyI6MCwidHlwZSI6InN0YWNrIn0sImlkIjoiLUFaMzM2S1JOaiIsIm5hbWUiOiIiLCJzdGFjayI6eyJiYWNrZ3Jv",
        "dW5kIjp7InR5cGUiOiJjb2xvciIsInZhbHVlIjp7ImxpZ2h0Ijp7InR5cGUiOiJoZXgiLCJ2YWx1ZSI6IiNGRkZGRkZGRiJ9fX0s",
        "ImJhY2tncm91bmRfY29sb3IiOm51bGwsImJhZGdlIjpudWxsLCJib3JkZXIiOm51bGwsImNvbXBvbmVudHMiOlt7ImJhY2tncm91",
        "bmRfY29sb3IiOm51bGwsImNvbG9yIjp7ImxpZ2h0Ijp7InR5cGUiOiJoZXgiLCJ2YWx1ZSI6IiNGRjAxMDFGRiJ9fSwiZm9udF9u",
        "YW1lIjpudWxsLCJmb250X3NpemUiOjE0LCJmb250X3dlaWdodCI6InJlZ3VsYXIiLCJmb250X3dlaWdodF9pbnQiOjQwMCwiaG9y",
        "aXpvbnRhbF9hbGlnbm1lbnQiOiJsZWFkaW5nIiwiaWQiOiI4VkdEM2gzVkNiIiwibWFyZ2luIjp7ImJvdHRvbSI6MCwibGVhZGlu",
        "ZyI6MCwidG9wIjowLCJ0cmFpbGluZyI6MH0sIm5hbWUiOiIiLCJwYWRkaW5nIjp7ImJvdHRvbSI6MCwibGVhZGluZyI6MCwidG9w",
        "IjowLCJ0cmFpbGluZyI6MH0sInNpemUiOnsiaGVpZ2h0Ijp7InR5cGUiOiJmaXQiLCJ2YWx1ZSI6bnVsbH0sIndpZHRoIjp7InR5",
        "cGUiOiJmaXQiLCJ2YWx1ZSI6bnVsbH19LCJ0ZXh0X2xpZCI6IlFlbjRHU2YybFciLCJ0eXBlIjoidGV4dCJ9XSwiZGltZW5zaW9u",
        "Ijp7ImFsaWdubWVudCI6ImxlYWRpbmciLCJkaXN0cmlidXRpb24iOiJzdGFydCIsInR5cGUiOiJ2ZXJ0aWNhbCJ9LCJpZCI6Ikps",
        "aEFPSzdJRTMiLCJtYXJnaW4iOnsiYm90dG9tIjowLCJsZWFkaW5nIjowLCJ0b3AiOjAsInRyYWlsaW5nIjowfSwibmFtZSI6Ikhl",
        "YWRlciIsInBhZGRpbmciOnsiYm90dG9tIjowLCJsZWFkaW5nIjowLCJ0b3AiOjAsInRyYWlsaW5nIjowfSwic2hhZG93Ijp7ImNv",
        "bG9yIjp7ImxpZ2h0Ijp7InR5cGUiOiJoZXgiLCJ2YWx1ZSI6IiMwMDAwMDAzMyJ9fSwicmFkaXVzIjoxNiwieCI6MCwieSI6NH0s",
        "InNoYXBlIjp7ImNvcm5lcnMiOnsiYm90dG9tX2xlYWRpbmciOjAsImJvdHRvbV90cmFpbGluZyI6MCwidG9wX2xlYWRpbmciOjAs",
        "InRvcF90cmFpbGluZyI6MH0sInR5cGUiOiJyZWN0YW5nbGUifSwic2l6ZSI6eyJoZWlnaHQiOnsidHlwZSI6ImZpdCIsInZhbHVl",
        "IjpudWxsfSwid2lkdGgiOnsidHlwZSI6ImZpbGwiLCJ2YWx1ZSI6bnVsbH19LCJzcGFjaW5nIjowLCJ0eXBlIjoic3RhY2sifSwi",
        "dHlwZSI6ImhlYWRlciJ9Cg=="
    ].joined()

    static let stackBase64 = [
        "eyJiYWNrZ3JvdW5kIjpudWxsLCJiYWNrZ3JvdW5kX2NvbG9yIjpudWxsLCJiYWRnZSI6bnVsbCwiYm9yZGVyIjpudWxsLCJjb21w",
        "b25lbnRzIjpbeyJib3JkZXIiOm51bGwsImNvbG9yX292ZXJsYXkiOm51bGwsImZpdF9tb2RlIjoiZmlsbCIsImlkIjoid2h1a2RY",
        "SGhaeSIsIm1hcmdpbiI6eyJib3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJtYXNrX3NoYXBlIjp7",
        "ImNvcm5lcnMiOm51bGwsInR5cGUiOiJjb252ZXgifSwibmFtZSI6IiIsInBhZGRpbmciOnsiYm90dG9tIjowLCJsZWFkaW5nIjow",
        "LCJ0b3AiOjAsInRyYWlsaW5nIjowfSwic2hhZG93IjpudWxsLCJzaXplIjp7ImhlaWdodCI6eyJ0eXBlIjoiZml0IiwidmFsdWUi",
        "Om51bGx9LCJ3aWR0aCI6eyJ0eXBlIjoiZmlsbCIsInZhbHVlIjpudWxsfX0sInNvdXJjZSI6eyJsaWdodCI6eyJoZWljIjoiaHR0",
        "cHM6Ly9hc3NldHMucGF3d2FsbHMuY29tLzExNzI1NjhfMTc3NDQ4NDgwNV9kNDgwYzhiMy5oZWljIiwiaGVpY19sb3dfcmVzIjoi",
        "aHR0cHM6Ly9hc3NldHMucGF3d2FsbHMuY29tLzExNzI1NjhfbG93X3Jlc18xNzc0NDg0ODA1X2Q0ODBjOGIzLmhlaWMiLCJoZWln",
        "aHQiOjEwMjQsIm9yaWdpbmFsIjoiaHR0cHM6Ly9hc3NldHMucGF3d2FsbHMuY29tLzExNzI1NjhfMTc3NDQ4NDgwNV9kNDgwYzhi",
        "My53ZWJwIiwid2VicCI6Imh0dHBzOi8vYXNzZXRzLnBhd3dhbGxzLmNvbS8xMTcyNTY4XzE3NzQ0ODQ4MDVfZDQ4MGM4YjMud2Vi",
        "cCIsIndlYnBfbG93X3JlcyI6Imh0dHBzOi8vYXNzZXRzLnBhd3dhbGxzLmNvbS8xMTcyNTY4X2xvd19yZXNfMTc3NDQ4NDgwNV9k",
        "NDgwYzhiMy53ZWJwIiwid2lkdGgiOjEwMjR9fSwidHlwZSI6ImltYWdlIn0seyJiYWNrZ3JvdW5kIjpudWxsLCJiYWNrZ3JvdW5k",
        "X2NvbG9yIjpudWxsLCJiYWRnZSI6bnVsbCwiYm9yZGVyIjpudWxsLCJjb21wb25lbnRzIjpbeyJiYWNrZ3JvdW5kX2NvbG9yIjpu",
        "dWxsLCJjb2xvciI6eyJsaWdodCI6eyJ0eXBlIjoiaGV4IiwidmFsdWUiOiIjMjcyNzI3RkYifX0sImZvbnRfbmFtZSI6bnVsbCwi",
        "Zm9udF9zaXplIjoyNCwiZm9udF93ZWlnaHQiOiJib2xkIiwiZm9udF93ZWlnaHRfaW50Ijo3MDAsImhvcml6b250YWxfYWxpZ25t",
        "ZW50IjoiY2VudGVyIiwiaWQiOiI1bUJ0VnZiQk1QIiwibWFyZ2luIjp7ImJvdHRvbSI6MCwibGVhZGluZyI6NTAsInRvcCI6MCwi",
        "dHJhaWxpbmciOjUwfSwibmFtZSI6IiIsInBhZGRpbmciOnsiYm90dG9tIjowLCJsZWFkaW5nIjowLCJ0b3AiOjAsInRyYWlsaW5n",
        "IjowfSwic2l6ZSI6eyJoZWlnaHQiOnsidHlwZSI6ImZpdCIsInZhbHVlIjpudWxsfSwid2lkdGgiOnsidHlwZSI6ImZpdCIsInZh",
        "bHVlIjpudWxsfX0sInRleHRfbGlkIjoibmpGel81My16RyIsInR5cGUiOiJ0ZXh0In1dLCJkaW1lbnNpb24iOnsiYWxpZ25tZW50",
        "IjoiY2VudGVyIiwiZGlzdHJpYnV0aW9uIjoiY2VudGVyIiwidHlwZSI6InZlcnRpY2FsIn0sImlkIjoicVdqQjRrd285UCIsIm1h",
        "cmdpbiI6eyJib3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJuYW1lIjoiIiwicGFkZGluZyI6eyJi",
        "b3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJzaGFkb3ciOm51bGwsInNoYXBlIjp7ImNvcm5lcnMi",
        "OnsiYm90dG9tX2xlYWRpbmciOjAsImJvdHRvbV90cmFpbGluZyI6MCwidG9wX2xlYWRpbmciOjAsInRvcF90cmFpbGluZyI6MH0s",
        "InR5cGUiOiJyZWN0YW5nbGUifSwic2l6ZSI6eyJoZWlnaHQiOnsidHlwZSI6ImZpdCIsInZhbHVlIjpudWxsfSwid2lkdGgiOnsi",
        "dHlwZSI6ImZpbGwiLCJ2YWx1ZSI6bnVsbH19LCJzcGFjaW5nIjoxNiwidHlwZSI6InN0YWNrIn1dLCJkaW1lbnNpb24iOnsiYWxp",
        "Z25tZW50IjoiY2VudGVyIiwiZGlzdHJpYnV0aW9uIjoic3RhcnQiLCJ0eXBlIjoidmVydGljYWwifSwiaWQiOiJ1aVFfbEl3a0xi",
        "IiwibWFyZ2luIjp7ImJvdHRvbSI6MCwibGVhZGluZyI6MCwidG9wIjowLCJ0cmFpbGluZyI6MH0sIm5hbWUiOiJDb250ZW50Iiwi",
        "cGFkZGluZyI6eyJib3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJzaGFkb3ciOm51bGwsInNoYXBl",
        "Ijp7ImNvcm5lcnMiOnsiYm90dG9tX2xlYWRpbmciOjAsImJvdHRvbV90cmFpbGluZyI6MCwidG9wX2xlYWRpbmciOjAsInRvcF90",
        "cmFpbGluZyI6MH0sInR5cGUiOiJyZWN0YW5nbGUifSwic2l6ZSI6eyJoZWlnaHQiOnsidHlwZSI6ImZpdCIsInZhbHVlIjpudWxs",
        "fSwid2lkdGgiOnsidHlwZSI6ImZpbGwiLCJ2YWx1ZSI6bnVsbH19LCJzcGFjaW5nIjo4LCJ0eXBlIjoic3RhY2sifQo="
    ].joined()

    static let stickyFooterBase64 = [
        "eyJpZCI6Inc4aEl3aklTZ1YiLCJuYW1lIjoiIiwic3RhY2siOnsiYmFja2dyb3VuZCI6eyJ0eXBlIjoiY29sb3IiLCJ2YWx1ZSI6",
        "eyJsaWdodCI6eyJ0eXBlIjoiaGV4IiwidmFsdWUiOiIjZmZmZmZmZmYifX19LCJiYWNrZ3JvdW5kX2NvbG9yIjpudWxsLCJiYWRn",
        "ZSI6bnVsbCwiYm9yZGVyIjpudWxsLCJjb21wb25lbnRzIjpbeyJiYWNrZ3JvdW5kIjpudWxsLCJiYWNrZ3JvdW5kX2NvbG9yIjpu",
        "dWxsLCJiYWRnZSI6bnVsbCwiYm9yZGVyIjpudWxsLCJjb21wb25lbnRzIjpbeyJpZCI6IkNaU0x4dlA5bkUiLCJpc19zZWxlY3Rl",
        "ZF9ieV9kZWZhdWx0Ijp0cnVlLCJuYW1lIjoiIiwicGFja2FnZV9pZCI6IiRyY19hbm51YWwiLCJzdGFjayI6eyJiYWNrZ3JvdW5k",
        "IjpudWxsLCJiYWNrZ3JvdW5kX2NvbG9yIjpudWxsLCJiYWRnZSI6bnVsbCwiYm9yZGVyIjpudWxsLCJjb21wb25lbnRzIjpbeyJi",
        "YWNrZ3JvdW5kX2NvbG9yIjpudWxsLCJjb2xvciI6eyJsaWdodCI6eyJ0eXBlIjoiaGV4IiwidmFsdWUiOiIjMjcyNzI3ZmYifX0s",
        "ImZvbnRfbmFtZSI6bnVsbCwiZm9udF9zaXplIjoxNCwiZm9udF93ZWlnaHQiOiJyZWd1bGFyIiwiaG9yaXpvbnRhbF9hbGlnbm1l",
        "bnQiOiJsZWFkaW5nIiwiaWQiOiItcS1WTGdOcXZDIiwibWFyZ2luIjp7ImJvdHRvbSI6MCwibGVhZGluZyI6MCwidG9wIjowLCJ0",
        "cmFpbGluZyI6MH0sIm5hbWUiOiIiLCJvdmVycmlkZXMiOlt7ImNvbmRpdGlvbnMiOlt7InR5cGUiOiJpbnRyb19vZmZlciJ9XSwi",
        "cHJvcGVydGllcyI6eyJjb2xvciI6eyJsaWdodCI6eyJ0eXBlIjoiaGV4IiwidmFsdWUiOiIjMDAwMDAwIn19LCJ0ZXh0X2xpZCI6",
        "IlFDWktaVFBqTk0ifX1dLCJwYWRkaW5nIjp7ImJvdHRvbSI6MCwibGVhZGluZyI6MCwidG9wIjowLCJ0cmFpbGluZyI6MH0sInNp",
        "emUiOnsiaGVpZ2h0Ijp7InR5cGUiOiJmaXQiLCJ2YWx1ZSI6bnVsbH0sIndpZHRoIjp7InR5cGUiOiJmaXQiLCJ2YWx1ZSI6bnVs",
        "bH19LCJ0ZXh0X2xpZCI6Imp2UzZqaVJhaXciLCJ0eXBlIjoidGV4dCJ9XSwiZGltZW5zaW9uIjp7ImFsaWdubWVudCI6ImNlbnRl",
        "ciIsImRpc3RyaWJ1dGlvbiI6InN0YXJ0IiwidHlwZSI6InZlcnRpY2FsIn0sImlkIjoicWM5SC1ERFVVZiIsIm1hcmdpbiI6eyJi",
        "b3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJuYW1lIjoiIiwicGFkZGluZyI6eyJib3R0b20iOjAs",
        "ImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJzaGFkb3ciOm51bGwsInNoYXBlIjp7ImNvcm5lcnMiOnsiYm90dG9t",
        "X2xlYWRpbmciOjgsImJvdHRvbV90cmFpbGluZyI6OCwidG9wX2xlYWRpbmciOjgsInRvcF90cmFpbGluZyI6OH0sInR5cGUiOiJy",
        "ZWN0YW5nbGUifSwic2l6ZSI6eyJoZWlnaHQiOnsidHlwZSI6ImZpdCIsInZhbHVlIjpudWxsfSwid2lkdGgiOnsidHlwZSI6ImZp",
        "bGwiLCJ2YWx1ZSI6bnVsbH19LCJzcGFjaW5nIjowLCJ0eXBlIjoic3RhY2sifSwidHlwZSI6InBhY2thZ2UifSx7ImlkIjoiV1Ff",
        "cGM5S0RTTSIsIm5hbWUiOiIiLCJzdGFjayI6eyJiYWNrZ3JvdW5kIjp7InR5cGUiOiJjb2xvciIsInZhbHVlIjp7ImxpZ2h0Ijp7",
        "ImRlZ3JlZXMiOjE1LCJwb2ludHMiOlt7ImNvbG9yIjoiIzdjZWNhN2ZmIiwicGVyY2VudCI6MH0seyJjb2xvciI6IiM3ZWYwZTNG",
        "RiIsInBlcmNlbnQiOjEwMH1dLCJ0eXBlIjoibGluZWFyIn19fSwiYmFja2dyb3VuZF9jb2xvciI6bnVsbCwiYmFkZ2UiOm51bGws",
        "ImJvcmRlciI6bnVsbCwiY29tcG9uZW50cyI6W3siYmFja2dyb3VuZF9jb2xvciI6bnVsbCwiY29sb3IiOnsibGlnaHQiOnsidHlw",
        "ZSI6ImhleCIsInZhbHVlIjoiIzBjMGMwY0ZGIn19LCJmb250X25hbWUiOm51bGwsImZvbnRfc2l6ZSI6MTYsImZvbnRfd2VpZ2h0",
        "Ijoic2VtaWJvbGQiLCJob3Jpem9udGFsX2FsaWdubWVudCI6ImNlbnRlciIsImlkIjoiWi1HZzZaY3EwZyIsIm1hcmdpbiI6eyJi",
        "b3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJuYW1lIjoiIiwib3ZlcnJpZGVzIjpbeyJjb25kaXRp",
        "b25zIjpbeyJ0eXBlIjoiaW50cm9fb2ZmZXIifV0sInByb3BlcnRpZXMiOnsiZm9udF9zaXplIjoxNCwidGV4dF9saWQiOiJ3dnEw",
        "aFp3ekhOIn19XSwicGFkZGluZyI6eyJib3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJzaXplIjp7",
        "ImhlaWdodCI6eyJ0eXBlIjoiZml0IiwidmFsdWUiOm51bGx9LCJ3aWR0aCI6eyJ0eXBlIjoiZml0IiwidmFsdWUiOm51bGx9fSwi",
        "dGV4dF9saWQiOiJSS0J1dlRnNktuIiwidHlwZSI6InRleHQifV0sImRpbWVuc2lvbiI6eyJhbGlnbm1lbnQiOiJjZW50ZXIiLCJk",
        "aXN0cmlidXRpb24iOiJzdGFydCIsInR5cGUiOiJ2ZXJ0aWNhbCJ9LCJpZCI6ImloZzF0ZDhtdWoiLCJtYXJnaW4iOnsiYm90dG9t",
        "IjowLCJsZWFkaW5nIjowLCJ0b3AiOjAsInRyYWlsaW5nIjowfSwibmFtZSI6IiIsInBhZGRpbmciOnsiYm90dG9tIjoxMiwibGVh",
        "ZGluZyI6OCwidG9wIjoxMiwidHJhaWxpbmciOjh9LCJzaGFkb3ciOnsiY29sb3IiOnsibGlnaHQiOnsidHlwZSI6ImhleCIsInZh",
        "bHVlIjoiIzhjZmZiYzgwIn19LCJyYWRpdXMiOjgsIngiOjQsInkiOjR9LCJzaGFwZSI6eyJjb3JuZXJzIjp7ImJvdHRvbV9sZWFk",
        "aW5nIjoxMiwiYm90dG9tX3RyYWlsaW5nIjoxMiwidG9wX2xlYWRpbmciOjEyLCJ0b3BfdHJhaWxpbmciOjEyfSwidHlwZSI6InJl",
        "Y3RhbmdsZSJ9LCJzaXplIjp7ImhlaWdodCI6eyJ0eXBlIjoiZml0IiwidmFsdWUiOm51bGx9LCJ3aWR0aCI6eyJ0eXBlIjoiZmls",
        "bCIsInZhbHVlIjpudWxsfX0sInNwYWNpbmciOjAsInR5cGUiOiJzdGFjayJ9LCJ0eXBlIjoicHVyY2hhc2VfYnV0dG9uIn1dLCJk",
        "aW1lbnNpb24iOnsiYWxpZ25tZW50IjoiY2VudGVyIiwiZGlzdHJpYnV0aW9uIjoiY2VudGVyIiwidHlwZSI6InZlcnRpY2FsIn0s",
        "ImlkIjoicUs0X2dnM3ZZbSIsIm1hcmdpbiI6eyJib3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJu",
        "YW1lIjoiIiwicGFkZGluZyI6eyJib3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJzaGFkb3ciOm51",
        "bGwsInNoYXBlIjp7ImNvcm5lcnMiOnsiYm90dG9tX2xlYWRpbmciOjAsImJvdHRvbV90cmFpbGluZyI6MCwidG9wX2xlYWRpbmci",
        "OjAsInRvcF90cmFpbGluZyI6MH0sInR5cGUiOiJyZWN0YW5nbGUifSwic2l6ZSI6eyJoZWlnaHQiOnsidHlwZSI6ImZpdCIsInZh",
        "bHVlIjpudWxsfSwid2lkdGgiOnsidHlwZSI6ImZpbGwiLCJ2YWx1ZSI6bnVsbH19LCJzcGFjaW5nIjoxMiwidHlwZSI6InN0YWNr",
        "In0seyJiYWNrZ3JvdW5kIjpudWxsLCJiYWNrZ3JvdW5kX2NvbG9yIjpudWxsLCJiYWRnZSI6bnVsbCwiYm9yZGVyIjpudWxsLCJj",
        "b21wb25lbnRzIjpbeyJhY3Rpb24iOnsidHlwZSI6InJlc3RvcmVfcHVyY2hhc2VzIn0sImlkIjoic3BodnpCV2ZYaCIsIm5hbWUi",
        "OiIiLCJzdGFjayI6eyJiYWNrZ3JvdW5kIjpudWxsLCJiYWNrZ3JvdW5kX2NvbG9yIjpudWxsLCJiYWRnZSI6bnVsbCwiYm9yZGVy",
        "IjpudWxsLCJjb21wb25lbnRzIjpbeyJiYWNrZ3JvdW5kX2NvbG9yIjpudWxsLCJjb2xvciI6eyJsaWdodCI6eyJ0eXBlIjoiaGV4",
        "IiwidmFsdWUiOiIjNTU1NTU1RkYifX0sImZvbnRfbmFtZSI6bnVsbCwiZm9udF9zaXplIjoxMywiZm9udF93ZWlnaHQiOiJzZW1p",
        "Ym9sZCIsImhvcml6b250YWxfYWxpZ25tZW50IjoibGVhZGluZyIsImlkIjoiLWlzS1ZTR2JyQyIsIm1hcmdpbiI6eyJib3R0b20i",
        "OjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJuYW1lIjoiIiwicGFkZGluZyI6eyJib3R0b20iOjAsImxlYWRp",
        "bmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJzaXplIjp7ImhlaWdodCI6eyJ0eXBlIjoiZml0IiwidmFsdWUiOm51bGx9LCJ3",
        "aWR0aCI6eyJ0eXBlIjoiZml0IiwidmFsdWUiOm51bGx9fSwidGV4dF9saWQiOiJrLXZLcExPTkZqIiwidHlwZSI6InRleHQifV0s",
        "ImRpbWVuc2lvbiI6eyJhbGlnbm1lbnQiOiJsZWFkaW5nIiwiZGlzdHJpYnV0aW9uIjoic3BhY2VfYmV0d2VlbiIsInR5cGUiOiJ2",
        "ZXJ0aWNhbCJ9LCJpZCI6ImplcUcwelgxb2QiLCJtYXJnaW4iOnsiYm90dG9tIjowLCJsZWFkaW5nIjowLCJ0b3AiOjAsInRyYWls",
        "aW5nIjowfSwibmFtZSI6IiIsInBhZGRpbmciOnsiYm90dG9tIjowLCJsZWFkaW5nIjowLCJ0b3AiOjAsInRyYWlsaW5nIjowfSwi",
        "c2hhZG93IjpudWxsLCJzaGFwZSI6eyJjb3JuZXJzIjp7ImJvdHRvbV9sZWFkaW5nIjowLCJib3R0b21fdHJhaWxpbmciOjAsInRv",
        "cF9sZWFkaW5nIjowLCJ0b3BfdHJhaWxpbmciOjB9LCJ0eXBlIjoicmVjdGFuZ2xlIn0sInNpemUiOnsiaGVpZ2h0Ijp7InR5cGUi",
        "OiJmaXQiLCJ2YWx1ZSI6bnVsbH0sIndpZHRoIjp7InR5cGUiOiJmaXQiLCJ2YWx1ZSI6bnVsbH19LCJzcGFjaW5nIjowLCJ0eXBl",
        "Ijoic3RhY2sifSwidHlwZSI6ImJ1dHRvbiJ9XSwiZGltZW5zaW9uIjp7ImFsaWdubWVudCI6InRvcCIsImRpc3RyaWJ1dGlvbiI6",
        "ImNlbnRlciIsInR5cGUiOiJob3Jpem9udGFsIn0sImlkIjoiUk1tcmJ6aW4xSCIsIm1hcmdpbiI6eyJib3R0b20iOjAsImxlYWRp",
        "bmciOjAsInRvcCI6MTIsInRyYWlsaW5nIjowfSwibmFtZSI6IkZvb3RlciBidXR0b25zIiwicGFkZGluZyI6eyJib3R0b20iOjAs",
        "ImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJzaGFkb3ciOm51bGwsInNoYXBlIjp7ImNvcm5lcnMiOnsiYm90dG9t",
        "X2xlYWRpbmciOjAsImJvdHRvbV90cmFpbGluZyI6MCwidG9wX2xlYWRpbmciOjAsInRvcF90cmFpbGluZyI6MH0sInR5cGUiOiJy",
        "ZWN0YW5nbGUifSwic2l6ZSI6eyJoZWlnaHQiOnsidHlwZSI6ImZpdCIsInZhbHVlIjpudWxsfSwid2lkdGgiOnsidHlwZSI6ImZp",
        "bGwiLCJ2YWx1ZSI6bnVsbH19LCJzcGFjaW5nIjozMiwidHlwZSI6InN0YWNrIn1dLCJkaW1lbnNpb24iOnsiYWxpZ25tZW50Ijoi",
        "bGVhZGluZyIsImRpc3RyaWJ1dGlvbiI6InN0YXJ0IiwidHlwZSI6InZlcnRpY2FsIn0sImlkIjoiTDc0cEZHQmxNayIsIm1hcmdp",
        "biI6eyJib3R0b20iOjAsImxlYWRpbmciOjAsInRvcCI6MCwidHJhaWxpbmciOjB9LCJuYW1lIjoiRm9vdGVyIiwicGFkZGluZyI6",
        "eyJib3R0b20iOjAsImxlYWRpbmciOjE2LCJ0b3AiOjEyLCJ0cmFpbGluZyI6MTZ9LCJzaGFkb3ciOnsiY29sb3IiOnsibGlnaHQi",
        "OnsidHlwZSI6ImhleCIsInZhbHVlIjoiIzAwMDAwMDBmIn19LCJyYWRpdXMiOjE2LCJ4IjowLCJ5IjotNH0sInNoYXBlIjp7ImNv",
        "cm5lcnMiOnsiYm90dG9tX2xlYWRpbmciOjAsImJvdHRvbV90cmFpbGluZyI6MCwidG9wX2xlYWRpbmciOjAsInRvcF90cmFpbGlu",
        "ZyI6MH0sInR5cGUiOiJyZWN0YW5nbGUifSwic2l6ZSI6eyJoZWlnaHQiOnsidHlwZSI6ImZpdCIsInZhbHVlIjpudWxsfSwid2lk",
        "dGgiOnsidHlwZSI6ImZpbGwiLCJ2YWx1ZSI6bnVsbH19LCJzcGFjaW5nIjowLCJ0eXBlIjoic3RhY2sifSwidHlwZSI6ImZvb3Rl",
        "ciJ9Cg=="
    ].joined()

    static let localizationsBase64 = [
        "eyJRQ1pLWlRQak5NIjoiVHJ5IGZyZWUgZm9yIHt7IHByb2R1Y3Qub2ZmZXJfcGVyaW9kX3dpdGhfdW5pdCB9fSwgdGhlbiB7eyBw",
        "cm9kdWN0LnByaWNlX3Blcl9wZXJpb2RfYWJicmV2aWF0ZWQgfX0iLCJRZW40R1NmMmxXIjoiVGV4dCIsIlJLQnV2VGc2S24iOiJD",
        "b250aW51ZSIsImp2UzZqaVJhaXciOiJTdWJzY3JpYmUgdG8gUHJvIGZvciBqdXN0IHt7IHByb2R1Y3QucHJpY2VfcGVyX3Blcmlv",
        "ZF9hYmJyZXZpYXRlZCB9fSIsImstdktwTE9ORmoiOiJSZXN0b3JlIFB1cmNoYXNlcyIsIm5qRnpfNTMtekciOiJVbmxvY2sgWW91",
        "ciBTbWFydGVzdCBTdHVkeSBSb3V0aW5lIiwid3ZxMGhad3pITiI6IlJlZGVlbSBteSBmcmVlIHt7IHByb2R1Y3Qub2ZmZXJfcGVy",
        "aW9kIH19In0K"
    ].joined()

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallPW3AA70E16BB844EB7Preview_Previews: PreviewProvider {

    static var previews: some View {
        PaywallsV2View(
            paywallComponents: PaywallPW3AA70E16BB844EB7Preview.paywallComponents,
            offering: PaywallPW3AA70E16BB844EB7Preview.offering,
            purchaseHandler: PurchaseHandler.default(),
            introEligibilityChecker: .default(),
            showZeroDecimalPlacePrices: false,
            onDismiss: {},
            fallbackContent: .customView(AnyView(Text("Fallback paywall"))),
            failedToLoadFont: { _ in },
            colorScheme: .light
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.safeAreaInsets, PaywallPW3AA70E16BB844EB7Preview.safeAreaInsets)
        .emergeExpansion(false)
        .previewLayout(.fixed(width: 393, height: 852))
        .previewDisplayName("pw3aa70e16bb844eb7")
    }

}

#endif

#endif
