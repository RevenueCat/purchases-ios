//
//  PackageCell.swift
//  Magic Weather
//
//  Created by Cody Kerns on 1/4/21.
//

import UIKit

/*
 The custom paywall package cell.
 Configured in /Resources/UI/Paywall.storyboard
 */

class PackageCell: UITableViewCell {

    @IBOutlet var packageTitleLabel: UILabel!
    @IBOutlet var packageTermsLabel: UILabel!
    @IBOutlet var packagePriceLabel: UILabel!

}
