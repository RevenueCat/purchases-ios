//
//  RCISOPeriodFormatter.h
//  Purchases
//
//  Created by Andrés Boedo on 5/26/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>



API_AVAILABLE(ios(11.2), macos(10.13.2), tvos(11.2))
NS_SWIFT_NAME(Purchases.ISOPeriodFormatter)
@interface RCISOPeriodFormatter: NSObject

- (NSString *)stringFromProductSubscriptionPeriod:(SKProductSubscriptionPeriod *)period;

@end
