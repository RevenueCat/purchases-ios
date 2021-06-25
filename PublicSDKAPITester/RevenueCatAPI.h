//
//  RevenueCatAPI.h
//  MigrateTester
//
//  Created by Joshua Liebowitz on 6/18/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RCPurchasesDelegate;

@interface RevenueCatAPI<RCPurchasesDelegate> : NSObject

+ (void)allTheThings;

@end

NS_ASSUME_NONNULL_END
