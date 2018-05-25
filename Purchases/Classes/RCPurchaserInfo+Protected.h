//
//  RCPurchaserInfo+Protected.h
//  Purchases
//
//  Created by Jacob Eiting on 10/22/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import "RCPurchaserInfo.h"

@interface RCPurchaserInfo (Protected)

- (instancetype _Nullable)initWithData:(NSDictionary * _Nonnull)data;

- (NSDictionary * _Nonnull)JSONObject;

@end
