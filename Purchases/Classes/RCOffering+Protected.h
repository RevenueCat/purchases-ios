//
//  RCOffering+Protected.h
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2018 RevenueCat, Inc. All rights reserved.
//

#import "RCOffering.h"

@interface RCOffering (Protected)

@property (readwrite) NSString *activeProductIdentifier;
@property (readwrite) SKProduct *activeProduct;

@end
