//
//  SplashScreenViewController.swift
//  Magic Weather
//
//  Created by Cody Kerns on 12/22/20.
//

import UIKit
import RevenueCat

/*
 Use a splash screen to make sure we have access to PurchaserInfo before displaying a UI.
 Configured in /Resources/UI/SplashScreen.storyboard
 */

class SplashScreenViewController: UIViewController {

    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var retryButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startAppForReal()
    }
    
    // - Since the splash screen is displayed first, this method attempts to start the app "for real"
    func startAppForReal() {
        Purchases.shared.getOfferings { (offerings, error) in
            if let error = error {
                self.catchError(error)
            } else {
                Purchases.shared.getCustomerInfo { (info, error) in
                    if let error = error {
                        self.catchError(error)
                    } else {
                        self.showMainView()
                    }
                }
            }
        }
    }
    
    func catchError(_ error: Error) {
        self.errorLabel.text = error.localizedDescription
        self.retryButton.isHidden = false
    }
    
    @IBAction
    func retryAfterError() {
        self.errorLabel.text = nil
        self.retryButton.isHidden = true
        
        startAppForReal()
    }
    
    func showMainView() {
        let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
        main.modalPresentationStyle = .fullScreen
        present(main, animated: true, completion: nil)
    }
    
}
