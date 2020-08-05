//
//  RCTransactionsFactory.h
//  Purchases
//
//  Created by Andrés Boedo on 8/5/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RCTransaction;

@interface RCTransactionsFactory: NSObject

- (NSArray <RCTransaction *> *) nonSubscriptionTransactionsWithSubscriptionsData:(NSDictionary *)subscriptionsData
                                                                   dateFormatter:(NSDateFormatter *)dateFormatter;

@end

NS_ASSUME_NONNULL_END
