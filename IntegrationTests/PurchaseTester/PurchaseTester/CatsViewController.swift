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

    private var customerInfoObservation: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        goPremiumButton.addTarget(self, action: #selector(goPremiumButtonTapped), for: .touchUpInside)
        manageSubButton.addTarget(self, action: #selector(manageSubButtonTapped), for: .touchUpInside)
        beginRefundButton.addTarget(self, action: #selector(beginRefundButtonTapped), for: .touchUpInside)
        restorePurchasesButton.addTarget(self, action: #selector(restorePurchasesButtonTapped), for: .touchUpInside)

        self.customerInfoObservation = Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                self.configureCatContentFor(customerInfo: customerInfo)
            }
        }
    }

    deinit {
        self.customerInfoObservation?.cancel()
    }
    
    func configureCatContentFor(customerInfo: CustomerInfo) {
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
    
    
    @objc func goPremiumButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc func manageSubButtonTapped() {
        Purchases.shared.showManageSubscriptions { error in
            if let error = error {
                print("Error opening Manage Subs Page: \(error.localizedDescription)")
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

                    let status = try await Purchases.shared.beginRefundRequest(forProduct: productID)

                    switch status {
                    case .success: print("Refund request submitted!")
                    case .userCancelled: print("Refund request cancelled")
                    case .error: print("Issue submitting refund request")
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
        Purchases.shared.restorePurchases { (customerInfo, error) in
            if let e = error {
                print("RESTORE ERROR: - \(e.localizedDescription)")
            }
            if let customerInfo = customerInfo {
                self.configureCatContentFor(customerInfo: customerInfo)
            }
                
        }
    }
}
