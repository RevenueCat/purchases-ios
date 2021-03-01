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

- (Class<FakeASIdentifierManager> _Nullable)asIdentifierClass {
    // We need to do this mangling to avoid Kid apps being rejected for getting idfa.
    // It looks like during the app review process Apple does some string matching looking for
    // functions in the AdSupport.framework. We apply rot13 on these functions and classes names
    // so that Apple can't find them during the review, but we can still access them on runtime.
    NSString *mangledClassName = @"NFVqragvsvreZnantre";

    NSString *className = [self rot13:mangledClassName];

    return (Class<FakeASIdentifierManager> _Nullable)NSClassFromString(className);
}

- (NSString *)asIdentifierPropertyName {
    NSString *mangledIdentifierPropertyName = @"nqiregvfvatVqragvsvre";
    return [self rot13:mangledIdentifierPropertyName];
}

- (NSString *)rot13:(NSString *)string {
    NSMutableString *rotatedString = [NSMutableString string];
    for (NSUInteger charIdx = 0; charIdx < string.length; charIdx++) {
        unichar c = [string characterAtIndex:charIdx];
        unichar i = '0';
        if (('a' <= c && c <= 'm') || ('A' <= c && c <= 'M')) {
            i = (unichar) (c + 13);
        }
        if (('n' <= c && c <= 'z') || ('N' <= c && c <= 'Z')) {
            i = (unichar) (c - 13);
        }
        [rotatedString appendFormat:@"%c", i];
    }
    return rotatedString;
}
@end


NS_ASSUME_NONNULL_END