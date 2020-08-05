//
//  RCLocalReceiptParser.h
//  Purchases
//
//  Created by Andrés Boedo on 8/5/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCLocalReceiptParser : NSObject

- (void)checkTrialOrIntroductoryPriceEligibilityWithData:(NSData *)data
                                      productIdentifiers:(NSArray <NSString *>*)productIdentifiers
                                              completion:(void (^)(NSDictionary<NSString *, NSNumber *> *,
                                                                   NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END

