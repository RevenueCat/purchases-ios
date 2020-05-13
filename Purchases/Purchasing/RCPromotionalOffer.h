//
//  RCPromotionalOffer.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCBackend.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCPromotionalOffer : NSObject

@property (nonatomic, readonly) NSString *offerIdentifier;

@property (nonatomic, readonly) NSDecimalNumber *price;

@property (nonatomic, readonly) enum RCPaymentMode paymentMode;

- (instancetype)initWithProductDiscount:(SKProductDiscount *)productDiscount API_AVAILABLE(ios(12.2), macos(10.14.4));

@end

NS_ASSUME_NONNULL_END
