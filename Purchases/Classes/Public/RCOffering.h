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

@property (readonly) SKProduct *activeProduct;

@end
