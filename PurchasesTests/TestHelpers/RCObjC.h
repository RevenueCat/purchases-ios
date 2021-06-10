//
//  RCObjC.h
//  Purchases
//
//  Created by Joshua Liebowitz on 6/10/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCObjC : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end

NS_ASSUME_NONNULL_END
