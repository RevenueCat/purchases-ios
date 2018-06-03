//
//  RCEntitlement.h
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2018 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCOffering;

@interface RCEntitlement : NSObject

@property (readonly) NSArray<RCOffering> *offerings;

@end
