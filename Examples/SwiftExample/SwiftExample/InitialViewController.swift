//
//  InitialViewController.swift
//  SwiftExample
//
//  Created by Ryan Kotzebue on 1/9/19.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import UIKit
import Purchases

class InitialViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Get the latest purchaserInfo to see if we have a pro cat user or not
        Purchases.shared.purchaserInfo { (purchaserInfo, error) in
            if let e = error {
                print(e.localizedDescription)
            }
            if let purchaserInfo = purchaserInfo {
                
                // Route the view depending if we have a premium cat user or not
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                var controller : UIViewController!

                
                if purchaserInfo.activeEntitlements.contains("pro_cat") {
                    
                    // if we have a pro_cat subscriber, send them to the cat screen
                    controller = storyboard.instantiateViewController(withIdentifier: "cats")
                    
                } else {
                    
                    // if we don't have a pro subscriber, send them to the upsell screen
                    controller = storyboard.instantiateViewController(withIdentifier: "upsell")
                }
                
                
                let nav = UINavigationController(rootViewController: controller)
                nav.navigationBar.isHidden = true
                self.present(nav, animated: true, completion: nil)
            }
        }
        
    }


}

