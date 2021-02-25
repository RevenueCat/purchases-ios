//
// Created by Andrés Boedo on 2/25/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

#import "RCAttributionTypeFactory.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RCAttributionTypeFactory

- (Class<FakeAdClient> _Nullable)adClientClass {
    return (Class<FakeAdClient> _Nullable)NSClassFromString(@"ADClient");
}

- (Class<FakeATTrackingManager> _Nullable)trackingManagerClass {
    return (Class<FakeATTrackingManager> _Nullable)NSClassFromString(@"ATTrackingManager");
}

@end


NS_ASSUME_NONNULL_END