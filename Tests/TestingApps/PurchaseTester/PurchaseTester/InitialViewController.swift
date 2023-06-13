//
//  InitialViewController.swift
//  PurchaseTester
//
//  Created by Ryan Kotzebue on 1/9/19.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import UIKit
import RevenueCat

class InitialViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Get the latest customerInfo to see if we have a pro cat user or not
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            if let e = error {
                print(e.localizedDescription)
            }
            
            let controllerToPresent: UIViewController

            // Route the view depending if we have a premium cat user or not
            if customerInfo?.entitlements["pro_cat"]?.isActive == true {
                
                // if we have a pro_cat subscriber, send them to the cat screen
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                controllerToPresent = storyboard.instantiateViewController(withIdentifier: "cats")
                controllerToPresent.modalPresentationStyle = .fullScreen
            } else {
                // if we don't have a pro subscriber, send them to the upsell screen
                let controller = SwiftPaywall(
                    termsOfServiceUrlString: "https://www.revenuecat.com/terms",
                    privacyPolicyUrlString: "https://www.revenuecat.com/terms"
                )
                
                controller.titleLabel.text = "Upsell Screen"
                controller.subtitleLabel.text = "New cats, unlimited cats, personal cat insights and more!"
                controller.modalPresentationStyle = .fullScreen

                controllerToPresent = controller
            }

            self.present(controllerToPresent, animated: true, completion: nil)

            // Present debug screen on top
            if #available(iOS 16.0, *) {
                controllerToPresent.presentDebugRevenueCatOverlay(animated: true)
            } else {
                print("Won't display debug overlay, not supported before iOS 16.0")
            }
        }
        
    }
}
