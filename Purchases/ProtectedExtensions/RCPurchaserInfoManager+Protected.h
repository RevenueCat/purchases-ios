//
//  RCPurchaserInfoManager+Protected.h
//  Purchases
//
//  Created by Andrés Boedo on 1/20/21.
//  Copyright © 2021 Purchases. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "RCPurchaserInfoManager.h"

NS_ASSUME_NONNULL_BEGIN

@class RCPurchaserInfo;

@interface RCPurchaserInfoManager (Protected)

@property (nonatomic, nullable) RCPurchaserInfo *lastSentPurchaserInfo;

@end

NS_ASSUME_NONNULL_END
