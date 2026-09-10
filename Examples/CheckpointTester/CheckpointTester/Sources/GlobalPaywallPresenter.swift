//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GlobalPaywallPresenter.swift
//
//  Created by Rick van der Linden.
//

import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI
import UIKit

@MainActor
final class GlobalPaywallPresenter: PaywallPresenter {

    static let shared = GlobalPaywallPresenter()

    func present(
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        PaywallPresenterDemo.present(style: .global, params: params, completion: completion)
    }

}

@MainActor
enum LocalPaywallPresenter {

    static let shared: PaywallPresentationHandler = { params, completion in
        PaywallPresenterDemo.present(style: .localOverride, params: params, completion: completion)
    }

}

@MainActor
private enum PaywallPresenterDemo {

    enum Style {
        case global
        case localOverride

        var title: String {
            switch self {
            case .global: return "Global presenter"
            case .localOverride: return "Local presenter override"
            }
        }

        var subtitle: String {
            switch self {
            case .global: return "Configured on Purchases.shared"
            case .localOverride: return "Passed to this checkpoint call"
            }
        }

        var tint: Color {
            switch self {
            case .global: return .blue
            case .localOverride: return .purple
            }
        }
    }

    static func present(
        style: Style,
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        guard let presenter = Self.presentationViewController else {
            completion(.closed)
            return
        }

        switch style {
        case .global:
            Self.presentGlobalSheet(
                from: presenter,
                params: params,
                completion: completion
            )
        case .localOverride:
            Self.presentLocalPopup(
                from: presenter,
                params: params,
                completion: completion
            )
        }
    }

    private static func presentGlobalSheet(
        from presenter: UIViewController,
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        let finish: (PaywallPresentationResult) -> Void = { result in
            completion(result)
            presenter.dismiss(animated: true)
        }
        let controller = UIHostingController(
            rootView: PaywallView(
                style: .global,
                offering: params.offering,
                onClose: {
                    finish(.closed)
                },
                onBack: {
                    finish(.navigatedBack)
                },
                onPurchase: {
                    finish(.purchased)
                }
            )
        )
        controller.modalPresentationStyle = .pageSheet
        presenter.present(controller, animated: true)
    }

    private static func presentLocalPopup(
        from presenter: UIViewController,
        params: PaywallPresentationParams,
        completion: @escaping PaywallPresentationCompletion
    ) {
        let finish: (PaywallPresentationResult) -> Void = { result in
            completion(result)
            presenter.dismiss(animated: true)
        }
        let controller = UIHostingController(
            rootView: LocalOverridePaywallPopup(
                offering: params.offering,
                onClose: {
                    finish(.closed)
                },
                onBack: {
                    finish(.navigatedBack)
                },
                onPurchase: {
                    finish(.purchased)
                }
            )
        )
        controller.modalPresentationStyle = .overFullScreen
        controller.view.backgroundColor = .clear
        presenter.present(controller, animated: false)
    }

    private static var presentationViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
            let rootViewController = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return nil
        }

        var viewController = rootViewController
        while let presentedViewController = viewController.presentedViewController {
            viewController = presentedViewController
        }
        return viewController
    }

}

private struct LocalOverridePaywallPopup: View {

    let offering: Offering
    let onClose: () -> Void
    let onBack: () -> Void
    let onPurchase: () -> Void

    @State private var isPresented = false
    @State private var isCelebrating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo.opacity(0.75), .purple.opacity(0.85), .pink.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                self.onBack()
            }

            ForEach(0 ..< 10, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                    .foregroundStyle(index.isMultiple(of: 2) ? .yellow : .white)
                    .font(.system(size: CGFloat(14 + index % 3 * 7)))
                    .offset(
                        x: self.isCelebrating ? CGFloat((index % 5 - 2) * 70) : 0,
                        y: self.isCelebrating ? CGFloat((index / 5 - 1) * 170) : 0
                    )
                    .rotationEffect(.degrees(self.isCelebrating ? Double(index * 72) : 0))
                    .opacity(self.isPresented ? 0.9 : 0)
            }

            VStack(spacing: 18) {
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.purple, .pink)
                    .rotationEffect(.degrees(self.isCelebrating ? 12 : -12))
                    .shadow(color: .purple.opacity(0.7), radius: 14)

                HStack(spacing: 8) {
                    Image(systemName: "paintbrush.pointed.fill")
                        .foregroundStyle(.purple)
                    Text("Local override")
                }
                .font(.title.bold())
                Text("This is app-owned UI, presented only for this checkpoint call.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Text("Offering: \(self.offering.identifier)")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.purple.opacity(0.12), in: Capsule())

                PackagePurchaseOptions(
                    offering: self.offering,
                    tint: .purple,
                    onPurchase: self.onPurchase
                )

                Button("Continue") {
                    self.onClose()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                Button("Back") {
                    self.onBack()
                }
                .buttonStyle(.bordered)
            }
            .padding(28)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 30, y: 14)
            .scaleEffect(self.isPresented ? 1 : 0.2)
            .rotationEffect(.degrees(self.isPresented ? 0 : -20))
            .opacity(self.isPresented ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                self.isPresented = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                self.isCelebrating = true
            }
        }
    }

}

private struct PaywallView: View {

    let style: PaywallPresenterDemo.Style
    let offering: Offering
    let onClose: () -> Void
    let onBack: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.largeTitle)
                    .foregroundStyle(self.style.tint)
                Text(self.style.title)
                    .font(.title.bold())
                Text(self.style.subtitle)
                    .font(.headline)
                    .foregroundStyle(self.style.tint)
                Text("Offering: \(self.offering.identifier)")
                    .foregroundStyle(.secondary)
                PackagePurchaseOptions(
                    offering: self.offering,
                    tint: self.style.tint,
                    onPurchase: self.onPurchase
                )
                Button("Continue") {
                    self.onClose()
                }
                .buttonStyle(.bordered)
                Button("Back") {
                    self.onBack()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .tint(self.style.tint)
    }

}

private struct PackagePurchaseOptions: View {

    let offering: Offering
    let tint: Color
    let onPurchase: () -> Void

    @State private var purchasingPackageIdentifier: String?
    @State private var purchaseError: String?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(self.offering.availablePackages) { package in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(package.storeProduct.localizedTitle)
                            .font(.subheadline.weight(.semibold))
                        Text(package.storeProduct.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Button {
                        self.purchase(package)
                    } label: {
                        if self.purchasingPackageIdentifier == package.identifier {
                            ProgressView()
                                .frame(width: 44)
                        } else {
                            VStack(spacing: 1) {
                                Text(package.storeProduct.localizedPriceString)
                                    .font(.caption.weight(.bold))
                                Text("Buy")
                                    .font(.caption2)
                            }
                            .frame(minWidth: 44)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(self.tint)
                    .disabled(self.purchasingPackageIdentifier != nil)
                }
                .padding(12)
                .background(self.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .alert(
            "Purchase failed",
            isPresented: Binding(
                get: { self.purchaseError != nil },
                set: { isPresented in
                    if !isPresented {
                        self.purchaseError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                self.purchaseError = nil
            }
        } message: {
            Text(self.purchaseError ?? "")
        }
    }

    private func purchase(_ package: Package) {
        guard self.purchasingPackageIdentifier == nil else { return }
        self.purchasingPackageIdentifier = package.identifier

        Task { @MainActor in
            defer { self.purchasingPackageIdentifier = nil }

            do {
                let result = try await Purchases.shared.purchase(package: package)
                if !result.userCancelled {
                    self.onPurchase()
                }
            } catch {
                self.purchaseError = error.localizedDescription
            }
        }
    }

}
