// AFServerTrustManager.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFServerTrustManager.h"
#import "AFSecurityPolicy.h"

static NSString *const AFServerTrustManagerErrorDomain = @"com.alamofire.afnetworking.servertrust";

#pragma mark - AFSecurityPolicyEvaluator

@implementation AFSecurityPolicyEvaluator

- (instancetype)initWithSecurityPolicy:(AFSecurityPolicy *)securityPolicy {
    self = [super init];
    if (self) {
        _securityPolicy = securityPolicy;
    }
    return self;
}

+ (instancetype)evaluatorWithSecurityPolicy:(AFSecurityPolicy *)securityPolicy {
    return [[self alloc] initWithSecurityPolicy:securityPolicy];
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                    forHost:(NSString *)host
                      error:(NSError * _Nullable __autoreleasing *)error {
    BOOL trusted = [self.securityPolicy evaluateServerTrust:serverTrust forDomain:host];
    if (!trusted && error) {
        *error = [NSError errorWithDomain:AFServerTrustManagerErrorDomain
                                     code:-1
                                 userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithFormat:
                                        @"Server trust evaluation failed for host: %@", host]
        }];
    }
    return trusted;
}

@end

#pragma mark - AFServerTrustManager

@implementation AFServerTrustManager

- (instancetype)init {
    return [self initWithEvaluators:@{}];
}

- (instancetype)initWithEvaluators:(NSDictionary<NSString *, id<AFServerTrustEvaluating>> *)evaluators {
    self = [super init];
    if (self) {
        _evaluators = [evaluators copy];
        _allUntrustedHostsMustBeEvaluated = NO;
    }
    return self;
}

+ (instancetype)managerWithEvaluators:(NSDictionary<NSString *, id<AFServerTrustEvaluating>> *)evaluators {
    return [[self alloc] initWithEvaluators:evaluators];
}

- (nullable id<AFServerTrustEvaluating>)evaluatorForHost:(NSString *)host {
    return self.evaluators[host];
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                    forHost:(NSString *)host
                      error:(NSError * _Nullable __autoreleasing *)error {
    id<AFServerTrustEvaluating> evaluator = [self evaluatorForHost:host];

    if (!evaluator) {
        if (self.allUntrustedHostsMustBeEvaluated) {
            if (error) {
                *error = [NSError errorWithDomain:AFServerTrustManagerErrorDomain
                                             code:-2
                                         userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:
                                                @"No evaluator found for host: %@", host]
                }];
            }
            return NO;
        }
        // 无评估器且不强制评估时，默认信任（与现有 AFN 行为一致）
        return YES;
    }

    return [evaluator evaluateServerTrust:serverTrust forHost:host error:error];
}

@end