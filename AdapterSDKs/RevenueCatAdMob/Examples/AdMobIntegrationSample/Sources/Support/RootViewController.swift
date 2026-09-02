import UIKit

/// Resolves the current key window's root view controller so full-screen ads can
/// be presented. Mirrors the helper most apps already have on hand.
enum RootViewController {

    static var current: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return windowScene.windows.first?.rootViewController
    }

}
