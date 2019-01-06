//
//  RCOffering.h
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2018 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKProduct;

/**
 Most well monetized subscription apps provide many different offerings to purchase an entitlement. These are usually associated with different durations i.e. an annual plan and a monthly plan. See [this link](https://docs.revenuecat.com/docs/entitlements) for more info
 */
NS_SWIFT_NAME(Offering)
@interface RCOffering : NSObject

/**
 The active product, this will be null if the product is not available, usually because it has not been approved for sale
 */
@property (readonly) SKProduct * _Nullable activeProduct;

- (NSString *)localizedPriceString;
- (NSString *)localizedIntroductoryPriceString;

@end
