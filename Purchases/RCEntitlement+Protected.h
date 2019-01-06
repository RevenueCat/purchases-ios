//
//  RCEntitlement+Protected.h
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCEntitlement.h"

@class RCOffering;

@interface RCEntitlement (Protected)

- (instancetype)initWithOfferings:(NSDictionary<NSString *, RCOffering *> *)offerings;

@end
