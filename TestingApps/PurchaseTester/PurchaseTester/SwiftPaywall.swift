//
//  SwiftPaywall.swift
//  PurchaseTester
//
//  Created by Ryan Kotzebue on 9/13/19.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import UIKit
import RevenueCat
import StoreKit

enum PayWallEdgeStyle : String {
    case square
    case soft
    case round
}

@objc protocol SwiftPaywallDelegate {
    func purchaseCompleted(paywall: SwiftPaywall, transaction: StoreTransaction, customerInfo: CustomerInfo)
    @objc optional func purchaseFailed(paywall: SwiftPaywall, customerInfo: CustomerInfo?, error: Error, userCancelled: Bool)
    @objc optional func purchaseRestored(paywall: SwiftPaywall, customerInfo: CustomerInfo?, error: Error?)
}

class SwiftPaywall: UIViewController {
    
    var delegate : SwiftPaywallDelegate?
    
    // Properties to initialize with
    private var textColor : UIColor
    private var productSelectedColor : UIColor
    private var productDeselectedColor : UIColor
    private var showDiscountPercentage : Bool
    private var edgeStyle : PayWallEdgeStyle
    private var offeringId : String?
    private var termsOfServiceURL : URL?
    private var privacyPolicyURL : URL?
    private var allowRestore : Bool
    
    // Views to optionally customize
    public var headerView : UIView!
    public var titleLabel : UILabel!
    public var subtitleLabel : UILabel!
    public var buyButton : UIButton!
    public var restoreButton : UIButton!
    public var freeTrialLabel : UILabel!
    public var termsAndConditionsLabel : UILabel!
    
    
    // Internal variables
    private var scrollView : UIScrollView!
    private var offering : Offering?
    private var offeringCollectionView : UICollectionView!
    private let maxItemsPerRow : CGFloat = 3
    private let aspectRatio : CGFloat = 1.3
    private let sectionInsets = UIEdgeInsets(top: 12.0,
                                             left: 12.0,
                                             bottom: 12.0,
                                             right: 12.0)
    
    // This determines the cell size
    private var widthPerPackage : CGFloat {
        let paddingSpace = sectionInsets.left * (maxItemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let maxWidth:CGFloat = 300.0
        return min(availableWidth / maxItemsPerRow, maxWidth)
    }
    
    private var offeringLoadingIndicator : UIActivityIndicatorView!
    private var buyButtonLoadingIndicator : UIActivityIndicatorView!
    private var closeButton : CloseButton!
    
    private var defaultBuyButtonText : String?
    private var defaultRestoreButtonText : String?
    
    private var didChangePackage = false
    
    
    init(termsOfServiceUrlString: String, // Required terms of service url string
        privacyPolicyUrlString: String, // Required privacy policy url string
        allowRestore: Bool = true, // Whether your app allows restoring purchases, default is true for most apps
        offeringId: String? = nil, // Offering ID, defaults to the current offering in RevenueCat
        edgeStyle: PayWallEdgeStyle = .round, // Corner radius style, defaults to round
        showDiscountPercentage: Bool = true, // Whether or not to show the discount badge on the products, default to true
        backgroundColor: UIColor = UIColor(red: 0.937, green: 0.286, blue: 0.314, alpha: 1.00), // Background color, defults to RevenueCat red
        textColor: UIColor = UIColor.white, // Text color, defaults to white
        productSelectedColor: UIColor = UIColor.white, // Selected product cell color, defaults to white
        productDeselectedColor: UIColor = UIColor.black) { // Deselected product cell color, defaults to black
        
        self.termsOfServiceURL = URL(string: termsOfServiceUrlString)
        self.privacyPolicyURL = URL(string: privacyPolicyUrlString)
        
        self.allowRestore = allowRestore
        self.offeringId = offeringId
        self.edgeStyle = edgeStyle
        self.showDiscountPercentage = showDiscountPercentage
        self.textColor = textColor
        self.productSelectedColor = productSelectedColor
        self.productDeselectedColor = productDeselectedColor
        
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = backgroundColor
        
        buildSubviews()
        loadOfferings()
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func loadOfferings() {
        
        offeringLoadingIndicator.startAnimating()
        buyButton.isEnabled = false
                
        Purchases.shared.getOfferings { (offerings, error) in
            
            if error != nil {
                self.showAlert(title: "Error", message: "Unable to fetch offerings.") { (action) in
                    self.close()
                }
            }
            if let offeringId = self.offeringId {
                self.offering = offerings?.offering(identifier: offeringId)
            } else {
                self.offering = offerings?.current
            }
            
            if self.offering == nil {
                self.showAlert(title: "Error", message: "No offerings found.") { (action) in
                    self.close()
                }
            }
            
            self.offeringLoadingIndicator.stopAnimating()
            self.offeringCollectionView.reloadData()
            self.buyButton.isEnabled = true
        }
    }
    
    @objc private func purchaseSelectedPackage() {
        guard let indexPath = offeringCollectionView.indexPathsForSelectedItems?.first else {
            print("No package selected")
            return
        }
        
        guard let package = offering?.availablePackages[indexPath.row] else {
            print("No available package")
            return
        }
        
        setState(loading: true)
        Purchases.shared.purchase(package: package) { (trans, info, error, cancelled) in

            self.setState(loading: false)

            if let error = error {
                if let purchaseFailedHandler = self.delegate?.purchaseFailed {
                    purchaseFailedHandler(self, info, error, cancelled)
                } else {
                    if !cancelled {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            } else {
                if let purchaseCompletedHandler = self.delegate?.purchaseCompleted {
                    purchaseCompletedHandler(self, trans!, info!)
                } else {
                    self.close()
                }
            }
        }
    }
    
    @objc private func restorePurchases() {
        setState(loading: true)
        Purchases.shared.restorePurchases { (info, error) in
            
            self.setState(loading: false)
            
            if let purchaseRestoredHandler = self.delegate?.purchaseRestored {
                purchaseRestoredHandler(self, info, error)
            } else {
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    if let customerInfo = info {
                        if customerInfo.entitlements.active.isEmpty {
                            self.showAlert(title: "Restore Unsuccessful", message: "No prior purchases found for your account.")
                        } else {
                            self.close()
                        }
                    }
                }
            }
        }
    }
    
    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func tapToCs(tap: UITapGestureRecognizer) {
        guard let text = termsAndConditionsLabel.text else {
            return
        }
        guard let tocRange = termsAndConditionsLabel.text?.range(of: "Terms of Service") else {
            return
        }
        guard let privacyRange = termsAndConditionsLabel.text?.range(of: "Privacy Policy") else {
            return
        }

        if tap.didTapAttributedTextInLabel(label: termsAndConditionsLabel, inRange: NSRange(tocRange, in: text)) {
            if let url = termsOfServiceURL {
                let nav = UINavigationController(rootViewController: WebViewController(url: url, title: "Terms of Service", textColor: view.backgroundColor, barColor: textColor))
                present(nav, animated: true, completion: nil)
            }
        } else if tap.didTapAttributedTextInLabel(label: termsAndConditionsLabel, inRange: NSRange(privacyRange, in: text)) {
            if let url = privacyPolicyURL {
                let nav = UINavigationController(rootViewController: WebViewController(url: url, title: "Privacy Policy", textColor: view.backgroundColor, barColor: textColor))
                present(nav, animated: true, completion: nil)
            }
        }
    }
    
    // Only call this right before purchasing or restoring
    private func setState(loading: Bool) {
        if loading {
            
            // This is to preserve the current button text after loading is shown
            defaultBuyButtonText = buyButton.titleLabel?.text
            defaultRestoreButtonText = restoreButton.titleLabel?.text

            buyButton.isEnabled = false
            buyButton.setTitle("", for: .normal)
            buyButtonLoadingIndicator.startAnimating()
            
            restoreButton.isEnabled = false
            restoreButton.setTitle("LOADING...", for: .normal)
            
            offeringCollectionView.isUserInteractionEnabled = false
            
            closeButton.isHidden = true
        } else {
            buyButton.isEnabled = true
            buyButton.setTitle(defaultBuyButtonText, for: .normal)
            buyButtonLoadingIndicator.stopAnimating()
            
            restoreButton.isEnabled = true
            restoreButton.setTitle(defaultRestoreButtonText, for: .normal)
            
            offeringCollectionView.isUserInteractionEnabled = true
            
            closeButton.isHidden = false
        }
    }
    
    private func shouldShowDiscount(package: Package?) -> (Bool, Package?) {
        return (showDiscountPercentage == true
                && mostAffordablePackages.count > 1
                && mostAffordablePackages.first?.storeProduct.productIdentifier == package?.storeProduct.productIdentifier, mostAffordablePackages.last)
    }
    
    private var mostAffordablePackages : [Package] {
        guard let sorted = offering?.availablePackages
            .filter({$0.packageType != .lifetime && $0.packageType != .custom})
            .sorted(by: { $1.annualCost() > $0.annualCost() }) else {
            return []
        }
        return sorted
    }
    
    private func showAlert(title: String?, message: String?, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: handler))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        // this computes the size of the scrollview to the bottom of the lowest subview + buffer
        scrollView.contentSize = CGSize(width: view.frame.width, height: restoreButton.frame.maxY+30)
    }
    
    private func buildSubviews() {
        
        // The scrollView
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        
        // The header is a UIView for customization
        headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            headerView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            headerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            headerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25),
            headerView.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])
        
        
        // The title label
        titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.minimumScaleFactor = 0.01
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 26)
        titleLabel.textColor = textColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -16.0),
            titleLabel.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16.0),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 44.0)
            ])
        
        // The offering container
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        offeringCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        offeringCollectionView.delegate = self
        offeringCollectionView.dataSource = self
        offeringCollectionView.showsHorizontalScrollIndicator = false
        offeringCollectionView.register(PackageCell.self, forCellWithReuseIdentifier: "cell")
        offeringCollectionView.translatesAutoresizingMaskIntoConstraints = false
        offeringCollectionView.backgroundColor = .clear
        scrollView.addSubview(offeringCollectionView)
        NSLayoutConstraint.activate([
            offeringCollectionView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            offeringCollectionView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            offeringCollectionView.heightAnchor.constraint(equalToConstant: view.frame.width/maxItemsPerRow*aspectRatio + sectionInsets.top*2),
            offeringCollectionView.centerYAnchor.constraint(equalTo: scrollView.topAnchor, constant: view.frame.height/2)
            ])
        
        // The offerings loading indicator
        if #available(iOS 13.0, *) {
            offeringLoadingIndicator = UIActivityIndicatorView(style: .medium)
        } else {
            offeringLoadingIndicator = UIActivityIndicatorView(style: .white)
        }
        offeringLoadingIndicator.hidesWhenStopped = true
        offeringLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        offeringCollectionView.addSubview(offeringLoadingIndicator)
        NSLayoutConstraint.activate([
            offeringLoadingIndicator.centerXAnchor.constraint(equalTo: offeringCollectionView.centerXAnchor),
            offeringLoadingIndicator.centerYAnchor.constraint(equalTo: offeringCollectionView.centerYAnchor)
            ])
        
        // The subtitle label
        subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 2
        subtitleLabel.minimumScaleFactor = 0.01
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        subtitleLabel.textColor = textColor
        subtitleLabel.alpha = 0.90
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            subtitleLabel.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -16.0),
            subtitleLabel.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16.0),
            subtitleLabel.bottomAnchor.constraint(equalTo: offeringCollectionView.topAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6.0)
            ])
        
        // The buy button
        buyButton = UIButton()
        buyButton.addTarget(self, action: #selector(purchaseSelectedPackage), for: .touchUpInside)
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        buyButton.backgroundColor = textColor
        buyButton.setTitle("Continue", for: .normal)
        buyButton.setTitleColor(view.backgroundColor, for: .normal)
        buyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)

        switch edgeStyle {
        case .round:
            buyButton.layer.cornerRadius = 25
        case .soft:
            buyButton.layer.cornerRadius = 8
        case .square:
            break
        }
        
        scrollView.addSubview(buyButton)
        NSLayoutConstraint.activate([
            buyButton.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -20.0),
            buyButton.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 20.0),
            buyButton.bottomAnchor.constraint(equalTo: scrollView.topAnchor, constant: view.frame.height-64),
            buyButton.heightAnchor.constraint(equalToConstant: 50.0)
            ])
        
        // The buy button loading indicator
        if #available(iOS 13.0, *) {
            buyButtonLoadingIndicator = UIActivityIndicatorView(style: .medium)
        } else {
            buyButtonLoadingIndicator = UIActivityIndicatorView(style: .white)
        }
        buyButtonLoadingIndicator.hidesWhenStopped = true
        buyButtonLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        buyButton.addSubview(buyButtonLoadingIndicator)
        NSLayoutConstraint.activate([
            buyButtonLoadingIndicator.centerXAnchor.constraint(equalTo: buyButton.centerXAnchor),
            buyButtonLoadingIndicator.centerYAnchor.constraint(equalTo: buyButton.centerYAnchor)
            ])
        
        // The free trial text label
        freeTrialLabel = UILabel()
        freeTrialLabel.numberOfLines = 2
        freeTrialLabel.minimumScaleFactor = 0.01
        freeTrialLabel.textAlignment = .center
        freeTrialLabel.font = UIFont.systemFont(ofSize: 14)
        freeTrialLabel.textColor = textColor
        freeTrialLabel.alpha = 0.90
        freeTrialLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(freeTrialLabel)
        NSLayoutConstraint.activate([
            freeTrialLabel.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -16.0),
            freeTrialLabel.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16.0),
            freeTrialLabel.bottomAnchor.constraint(equalTo: buyButton.topAnchor, constant: -4.0),
            freeTrialLabel.topAnchor.constraint(equalTo: offeringCollectionView.bottomAnchor)
            ])
        
        // The Terms & Conditions Label
        termsAndConditionsLabel = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToCs(tap:)))
        termsAndConditionsLabel.addGestureRecognizer(tap)
        termsAndConditionsLabel.isUserInteractionEnabled = true
        termsAndConditionsLabel.numberOfLines = 2
        termsAndConditionsLabel.minimumScaleFactor = 0.01
        termsAndConditionsLabel.textAlignment = .center
        termsAndConditionsLabel.font = UIFont.systemFont(ofSize: 12)
        termsAndConditionsLabel.textColor = textColor
        termsAndConditionsLabel.alpha = 0.90
        

        let linkAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)]
        let firstLine = NSMutableAttributedString(string: "By continuing, you agree to our\n")
        let termsText = NSAttributedString(string: "Terms of Service", attributes: linkAttributes)
        let and = NSAttributedString(string: " and ")
        let privacyText = NSAttributedString(string: "Privacy Policy", attributes: linkAttributes)
        
        firstLine.append(termsText)
        firstLine.append(and)
        firstLine.append(privacyText)
        termsAndConditionsLabel.attributedText = firstLine
        
        termsAndConditionsLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(termsAndConditionsLabel)
        NSLayoutConstraint.activate([
            termsAndConditionsLabel.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -16.0),
            termsAndConditionsLabel.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16.0),
            termsAndConditionsLabel.topAnchor.constraint(equalTo: buyButton.bottomAnchor, constant: 42.0),
            termsAndConditionsLabel.heightAnchor.constraint(equalToConstant: 30.0)
            ])
        
        // The restore button
        restoreButton = UIButton()
        restoreButton.addTarget(self, action: #selector(restorePurchases), for: .touchUpInside)
        restoreButton.translatesAutoresizingMaskIntoConstraints = false
        restoreButton.setTitle("RESTORE PURCHASES", for: .normal)
        restoreButton.setTitleColor(textColor.withAlphaComponent(0.6), for: .normal)
        restoreButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        restoreButton.isHidden = !allowRestore
        
        scrollView.addSubview(restoreButton)
        NSLayoutConstraint.activate([
            restoreButton.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -20.0),
            restoreButton.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 20.0),
            restoreButton.topAnchor.constraint(equalTo: termsAndConditionsLabel.bottomAnchor, constant: 35.0),
            restoreButton.heightAnchor.constraint(equalToConstant: 50.0)
            ])
        
        // The close button
        closeButton = CloseButton(backgroundColor: productDeselectedColor, textColor: textColor)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        scrollView.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 20.0),
            closeButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 30.0),
            closeButton.widthAnchor.constraint(equalToConstant: 30.0),
            closeButton.heightAnchor.constraint(equalToConstant: 30.0)
            ])
    }
}

extension SwiftPaywall: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return offering?.availablePackages.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let package = offering?.availablePackages[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PackageCell
        cell.setupWith(
            package: package,
            discount: shouldShowDiscount(package: package),
            edgeStyle: edgeStyle,
            productSelectedColor: productSelectedColor,
            productDeselectedColor: productDeselectedColor)
        
        // Should this package be selected
        if !didChangePackage && mostAffordablePackages.first?.storeProduct.productIdentifier == package?.storeProduct.productIdentifier {
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
            cell.isSelected = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        didChangePackage = true

        if #available(iOS 12.2, *) {
            if let product = offering?.availablePackages[indexPath.row].storeProduct,
               let introPrice = product.introductoryDiscount, introPrice.price == 0 {

                var trialLength = ""
                var cancelDate : Date?
                var cancelString = "end of trial"
                let numUnits = introPrice.subscriptionPeriod.value

                switch introPrice.subscriptionPeriod.unit {
                case .day:
                    trialLength = "\(numUnits)-day"
                    cancelDate = Calendar.current.date(byAdding: .day, value: numUnits-1, to: Date())
                case .week:
                    trialLength = "\(numUnits*7)-day"
                    cancelDate = Calendar.current.date(byAdding: .day, value: 7*numUnits-1, to: Date())
                case .month:
                    trialLength = "\(numUnits)-month"
                    cancelDate = Calendar.current.date(byAdding: .month, value: numUnits, to: Date())
                    cancelDate = Calendar.current.date(byAdding: .day, value: -1, to: cancelDate ?? Date())
                case .year:
                    trialLength = "\(numUnits)-year"
                    cancelDate = Calendar.current.date(byAdding: .year, value: numUnits, to: Date())
                    cancelDate = Calendar.current.date(byAdding: .day, value: -1, to: cancelDate ?? Date())
                @unknown default:
                    fatalError("Unknown unit: \(introPrice.subscriptionPeriod.unit)")
                }

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM d"
                if let cancelDate = cancelDate {
                    cancelString = dateFormatter.string(from: cancelDate)
                }

                let dateAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)]
                let baseText = NSMutableAttributedString(string: "Includes \(trialLength) free trial. Cancel before ")
                let cancelAttributedText = NSAttributedString(string: cancelString, attributes: dateAttributes)
                let and = NSAttributedString(string: " and nothing will be billed.")

                baseText.append(cancelAttributedText)
                baseText.append(and)

                freeTrialLabel.attributedText = baseText
            } else {
                freeTrialLabel.text = nil
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: widthPerPackage, height: widthPerPackage*aspectRatio)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let packagesCount = offering?.availablePackages.count ?? 0
        
        if CGFloat(packagesCount) < maxItemsPerRow {
            
            let totalCellWidth = widthPerPackage * CGFloat(packagesCount)
            let totalSpacingWidth = sectionInsets.left * CGFloat(packagesCount - 1)
            
            let leftInset = (collectionView.frame.width - (totalCellWidth + totalSpacingWidth)) / 2
            
            return UIEdgeInsets(
                top: sectionInsets.top,
                left: leftInset,
                bottom: sectionInsets.bottom,
                right: leftInset)
        } else {
            return sectionInsets
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
}

private class PackageCell : UICollectionViewCell {
    
    let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()
    
    let discountLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = UIColor(red: 0.165, green: 0.663, blue: 0.545, alpha: 1.00)
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.1
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.minimumScaleFactor = 0.1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.numberOfLines = 1
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let monthlyPriceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.numberOfLines = 1
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let discountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent

        return formatter
    }()
    var highlightColor : UIColor?
    var secondaryColor : UIColor?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildSubviews()
    }
    
    override var isSelected: Bool {
        didSet {
            setHighlighted(self.isSelected)
        }
    }
    
    func setHighlighted( _ highlighted: Bool) {
        if highlighted {
            containerView.backgroundColor = highlightColor
            durationLabel.textColor = secondaryColor?.withAlphaComponent(0.6)
            priceLabel.textColor = secondaryColor?.withAlphaComponent(0.9)
            monthlyPriceLabel.textColor = secondaryColor?.withAlphaComponent(0.7)
        } else {
            containerView.backgroundColor = secondaryColor?.withAlphaComponent(0.1)
            durationLabel.textColor = highlightColor?.withAlphaComponent(0.5)
            priceLabel.textColor = highlightColor?.withAlphaComponent(0.5)
            monthlyPriceLabel.textColor = highlightColor?.withAlphaComponent(0.5)
        }
    }
    
    fileprivate func setMonthlyPriceLabel(_ package: Package) {
        guard let formatter = package.storeProduct.priceFormatter else {
            return
        }

        guard let monthlyPrice = package.storeProduct.pricePerMonth else {
            fatalError("Package is not a subscription: \(package)")
        }

        monthlyPriceLabel.text = "\(formatter.string(from: monthlyPrice as NSDecimalNumber) ?? "") / mo"
    }

    func setupWith(
        package: Package?,
        discount: (Bool, Package?),
        edgeStyle: PayWallEdgeStyle = .round,
        productSelectedColor: UIColor? = nil,
        productDeselectedColor: UIColor? = nil) {
                
        guard let package = package else {
            durationLabel.text = nil
            discountLabel.isHidden = true
            priceLabel.text = nil
            monthlyPriceLabel.text = nil
            return
        }
        
        self.highlightColor = productSelectedColor
        self.secondaryColor = productDeselectedColor
        
        switch edgeStyle {
        case .round:
            containerView.layer.cornerRadius = 12
        case .soft:
            containerView.layer.cornerRadius = 8
        case .square:
            break
        }
        
        containerView.backgroundColor = secondaryColor?.withAlphaComponent(0.1)
        durationLabel.backgroundColor = secondaryColor?.withAlphaComponent(0.08)
        setHighlighted(isSelected)
        
        discountLabel.isHidden = !discount.0
        
        if discount.0, let discount = discount.1 {
            let d = Self.discountBetween(highest: discount, current: package)
            let save = self.discountFormatter.string(from: d as NSDecimalNumber)

            discountLabel.text = "SAVE \(save ?? "")"
        }
            
        priceLabel.text = package.localizedPriceString
        
        switch package.packageType {
        case .lifetime:
            durationLabel.text = "LIFETIME"
            monthlyPriceLabel.text = "ONE TIME"
            discountLabel.isHidden = true
        case .annual:
            durationLabel.text = "1\nYEAR"
            setMonthlyPriceLabel(package)
        case .sixMonth:
            durationLabel.text = "6\nMONTHS"
            setMonthlyPriceLabel(package)
        case .threeMonth:
            durationLabel.text = "3\nMONTHS"
            setMonthlyPriceLabel(package)
        case .twoMonth:
            durationLabel.text = "2\nMONTHS"
            setMonthlyPriceLabel(package)
        case .monthly:
            durationLabel.text = "1\nMONTH"
            monthlyPriceLabel.text = "\(package.localizedPriceString) / mo"
        case .weekly:
            durationLabel.text = "1\nWEEK"
            monthlyPriceLabel.text = "\(package.localizedPriceString) / wk"
        case .custom, .unknown:
            durationLabel.text = package.identifier.uppercased()
            discountLabel.isHidden = true
            monthlyPriceLabel.text = nil
        }
    }
    
    private static func discountBetween(highest: Package, current: Package) -> Decimal {
        let highestAnnualCost : Decimal!
        switch highest.packageType {
        case .annual:
            highestAnnualCost = highest.storeProduct.price
        case .sixMonth:
            highestAnnualCost = highest.storeProduct.price * 2.0
        case .threeMonth:
            highestAnnualCost = highest.storeProduct.price * 4.0
        case .twoMonth:
            highestAnnualCost = highest.storeProduct.price * 6.0
        case .monthly:
            highestAnnualCost = highest.storeProduct.price * 12.0
        case .weekly:
            highestAnnualCost = highest.storeProduct.price * 52.0
        case .lifetime, .custom, .unknown:
            return 0.0
        }
        
        let currentAnnualCost : Decimal!
        switch current.packageType {
        case .annual:
            currentAnnualCost = current.storeProduct.price
        case .sixMonth:
            currentAnnualCost = current.storeProduct.price * 2.0
        case .threeMonth:
            currentAnnualCost = current.storeProduct.price * 4.0
        case .twoMonth:
            currentAnnualCost = current.storeProduct.price * 6.0
        case .monthly:
            currentAnnualCost = current.storeProduct.price * 12.0
        case .weekly:
            currentAnnualCost = current.storeProduct.price * 52.0
        case .lifetime, .custom, .unknown:
            return 0.0
        }
        
        return (highestAnnualCost - currentAnnualCost) / highestAnnualCost
    }
    
    func buildSubviews() {
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: self.topAnchor),
            containerView.leftAnchor.constraint(equalTo: self.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: self.rightAnchor)
            ])
        
        containerView.addSubview(durationLabel)
        NSLayoutConstraint.activate([
            durationLabel.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.5),
            durationLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            durationLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            durationLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            ])
        
        containerView.addSubview(priceLabel)
        NSLayoutConstraint.activate([
            priceLabel.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 8),
            priceLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            priceLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            priceLabel.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.20)
            ])
        
        containerView.addSubview(monthlyPriceLabel)
        NSLayoutConstraint.activate([
            monthlyPriceLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor),
            monthlyPriceLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            monthlyPriceLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            monthlyPriceLabel.heightAnchor.constraint(equalToConstant: 17.0)
            ])
        
        addSubview(discountLabel)
        discountLabel.layer.cornerRadius = 10
        discountLabel.clipsToBounds = true
        NSLayoutConstraint.activate([
            discountLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8),
            discountLabel.heightAnchor.constraint(equalToConstant: 20),
            discountLabel.centerYAnchor.constraint(equalTo: self.topAnchor),
            discountLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate extension Package {
    
    func annualCost() -> Decimal {
        switch self.packageType {
        case .annual:
            return self.storeProduct.price
        case .sixMonth:
            return self.storeProduct.price * 2
        case .threeMonth:
            return self.storeProduct.price * 4
        case .twoMonth:
            return self.storeProduct.price * 6
        case .monthly:
            return self.storeProduct.price * 12
        case .weekly:
            return self.storeProduct.price * 52
        case .lifetime, .custom, .unknown:
            return 0.0
        }
    }
}

private class CloseButton : UIButton {
    
    private struct Constants {
        static let plusLineWidth: CGFloat = 3.0
        static let plusButtonScale: CGFloat = 0.5
    }
    
    private var halfWidth: CGFloat {
        return bounds.width / 2
    }
    
    private var halfHeight: CGFloat {
        return bounds.height / 2
    }
    
    private var bgColor : UIColor
    private var txtColor : UIColor
    
    init(backgroundColor: UIColor, textColor: UIColor) {
        
        bgColor = backgroundColor
        txtColor = textColor
        
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        bgColor.withAlphaComponent(0.1).setFill()
        path.fill()
        
        //set up the width and height variables
        //for the horizontal stroke
        let plusWidth: CGFloat = min(bounds.width, bounds.height) * Constants.plusButtonScale
        let halfPlusWidth = (plusWidth / 2) / sqrt(2)
        
        //create the plus
        let plusPath = UIBezierPath()
        
        //move the initial point of the path
        //to the start of the horizontal stroke
        plusPath.move(to: CGPoint(
            x: halfWidth - halfPlusWidth,
            y: halfHeight - halfPlusWidth))
        
        //add a point to the path at the end of the stroke
        plusPath.addLine(to: CGPoint(
            x: halfWidth + halfPlusWidth,
            y: halfHeight + halfPlusWidth))
        
        //move the initial point of the path
        //to the start of the vertical stroke
        plusPath.move(to: CGPoint(
            x: halfWidth - halfPlusWidth,
            y: halfHeight + halfPlusWidth))
        
        //add a point to the path at the end of the stroke
        plusPath.addLine(to: CGPoint(
            x: halfWidth + halfPlusWidth,
            y: halfHeight - halfPlusWidth))
        
        //set the stroke color
        txtColor.withAlphaComponent(0.5).setStroke()
        
        //set the details
        plusPath.lineCapStyle = .round
        plusPath.lineWidth = Constants.plusLineWidth
        
        //draw the stroke
        plusPath.stroke()
    }
}

import WebKit
private class WebViewController: UIViewController {
    
    var url : URL
    var webView : WKWebView!
    var textColor : UIColor?
    var barColor : UIColor?
    
    init(url: URL, title: String?, textColor: UIColor?, barColor: UIColor?) {
        self.url = url
        self.textColor = textColor
        self.barColor = barColor
        super.init(nibName: nil, bundle: nil)
        
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView = WKWebView(frame: view.frame, configuration: WKWebViewConfiguration())
        webView.load(URLRequest(url: url))
        view.addSubview(webView)
        
        // reconfig the navigation bar
        navigationController?.navigationBar.tintColor = textColor
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor : textColor ?? .black
        ]
        navigationController?.navigationBar.barTintColor = barColor
        navigationController?.navigationBar.isTranslucent = false
        UINavigationBar.appearance().shadowImage = UIImage()
        
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(close))

    }
    
    @objc func close() {
        dismiss(animated: true, completion: nil)
    }
}


fileprivate extension UITapGestureRecognizer {
    
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText ?? NSAttributedString(string: ""))
        
        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        
        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}
