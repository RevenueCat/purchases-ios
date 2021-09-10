//
//  RevenueCatAPI.h
//  RCPurchasesAPI
//
//  Created by Joshua Liebowitz on 6/18/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RCPurchasesDelegate;

@interface RCPurchasesAPI<RCPurchasesDelegate> : NSObject

+ (void)checkAPI;
+ (void)checkEnums;
+ (void)checkConstants;

@end

NS_ASSUME_NONNULL_END
