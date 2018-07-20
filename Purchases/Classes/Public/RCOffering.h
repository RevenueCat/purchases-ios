//
//  RCOffering.h
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2018 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKProduct;

@interface RCOffering : NSObject

// The active product, this will be null if the product is not available, usually because it has not been approved
// for sale
@property (readonly) SKProduct * _Nullable activeProduct;

@end
