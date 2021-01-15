//
//  RCIdentityManager+Protected.h
//  Purchases
//
//  Created by Andrés Boedo on 1/15/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCIdentityManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCIdentityManager (Protected)

- (NSString *)generateRandomID;

@end

NS_ASSUME_NONNULL_END
