//
//  RCOffering+Protected.h
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//

#import "RCOffering.h"

@interface RCOffering (Protected)

@property (readwrite, nonatomic) NSString *activeProductIdentifier;
@property (readwrite, nonatomic) SKProduct *activeProduct;

@end
