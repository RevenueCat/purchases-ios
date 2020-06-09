//
// Created by Andrés Boedo on 5/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SKProduct, RCProductInfo;

NS_ASSUME_NONNULL_BEGIN


@interface RCProductInfoExtractor : NSObject

- (RCProductInfo *)extractInfoFromProduct:(SKProduct *)product;

@end


NS_ASSUME_NONNULL_END
