#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import UIKit

@MainActor
final class RewardedAdPromptTestWindow: UIWindow {

    init(rootViewController: UIViewController) {
        super.init(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        self.rootViewController = rootViewController
        self.isHidden = false
        rootViewController.loadViewIfNeeded()
        self.layoutIfNeeded()
        rootViewController.view.layoutIfNeeded()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
#endif
