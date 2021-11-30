//
//  CatsViewController.swift
//  PurchaseTester
//
//  Created by Ryan Kotzebue on 1/9/19.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import UIKit
import RevenueCat

class CatsViewController: UIViewController {
    
    @IBOutlet weak var goPremiumButton: UIButton!
    @IBOutlet weak var manageSubButton: UIButton!
    @IBOutlet weak var beginRefundButton: UIButton!
    @IBOutlet weak var restorePurchasesButton: UIButton!
    @IBOutlet weak var catContentLabel: UILabel!
    @IBOutlet weak var expirationDateLabel: UILabel!
    @IBOutlet weak var purchaseDateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        goPremiumButton.addTarget(self, action: #selector(goPremiumButtonTapped), for: .touchUpInside)
        manageSubButton.addTarget(self, action: #selector(manageSubButtonTapped), for: .touchUpInside)
        beginRefundButton.addTarget(self, action: #selector(beginRefundButtonTapped), for: .touchUpInside)
        restorePurchasesButton.addTarget(self, action: #selector(restorePurchasesButtonTapped), for: .touchUpInside)
        
        Purchases.shared.getCustomerInfo{ (maybeCustomerInfo, error) in
            self.configureCatContentFor(customerInfo: maybeCustomerInfo)
        }

    }
    
    func configureCatContentFor(customerInfo maybeCustomerInfo: CustomerInfo?) {
        
        // set the content based on the user subscription status
        if let customerInfo = maybeCustomerInfo {
            
            if customerInfo.entitlements["pro_cat"]?.isActive == true {
                
                print("Hey there premium, you're a happy cat 😻")
                self.catContentLabel.text = "😻"
                self.goPremiumButton.isHidden = true
                self.restorePurchasesButton.isHidden = true
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                
                if let purchaseDate = customerInfo.purchaseDate(forEntitlement: "pro_cat") {
                    self.purchaseDateLabel.text = "Purchase Date: \(dateFormatter.string(from: purchaseDate))"
                }
                if let expirationDate = customerInfo.expirationDate(forEntitlement: "pro_cat") {
                    self.expirationDateLabel.text = "Expiration Date: \(dateFormatter.string(from: expirationDate))"
                }

                
            } else {
                print("Happy cats are only for premium members 😿")
                self.catContentLabel.text = "😿"
                self.beginRefundButton.isHidden = true
            }
        }
    }
    
    
    @objc func goPremiumButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc func manageSubButtonTapped() {
        Purchases.shared.showManageSubscriptionModal { maybeError in
            if let error = maybeError {
                print("Error opening Manage Sub Modal: \(error.localizedDescription)")
            }
        }
    }

    @objc func beginRefundButtonTapped() {
        if #available(iOS 15.0, *) {
            _ = Task<Void, Never> {
                do {
                    let customerInfo = try await Purchases.shared.customerInfo()
                    guard let activeEntitlement = customerInfo.entitlements.active.first else {
                        print("no current entitlement available, can't begin a refund request!")
                        return
                    }

                    let productID = activeEntitlement.value.productIdentifier

                    Purchases.shared.beginRefundRequest(for: productID)
                    { status, maybeError in
                        switch status {
                        case .success: print("Refund request submitted!")
                        case .userCancelled: print("Refund request cancelled")
                        case .error: print("Issue submitting refund request: \(maybeError?.localizedDescription ?? "")")
                        }
                    }

                }
                catch {
                    print("Couldn't fetch customerInfo! Details: \(error.localizedDescription)")
                }
            }
        } else {
            print("Refund requests not supported")
        }
    }
    
    @objc func restorePurchasesButtonTapped() {
        Purchases.shared.restoreTransactions { (customerInfo, error) in
            if let e = error {
                print("RESTORE ERROR: - \(e.localizedDescription)")
            }
            self.configureCatContentFor(customerInfo: customerInfo)
                
        }
    }
}
