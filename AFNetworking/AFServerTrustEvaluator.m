// AFServerTrustEvaluator.m
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

#import "AFServerTrustEvaluator.h"

NSErrorDomain const AFServerTrustErrorDomain = @"com.alamofire.error.servertrust";

static NSError *AFServerTrustError(NSString *message) {
    return [NSError errorWithDomain:AFServerTrustErrorDomain
                               code:-1
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

// MARK: - AFSecurityPolicyEvaluator

@implementation AFSecurityPolicyEvaluator

- (instancetype)initWithSecurityPolicy:(AFSecurityPolicy *)securityPolicy {
    self = [super init];
    if (self) {
        _securityPolicy = securityPolicy;
    }
    return self;
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forHost:(NSString *)host error:(NSError **)error {
    if ([self.securityPolicy evaluateServerTrust:serverTrust forDomain:host]) {
        return YES;
    }
    if (error) {
        *error = AFServerTrustError([NSString stringWithFormat:@"Server trust evaluation failed for host: %@", host]);
    }
    return NO;
}

@end

// MARK: - AFDefaultTrustEvaluator

@implementation AFDefaultTrustEvaluator

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forHost:(NSString *)host error:(NSError **)error {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    policy.allowInvalidCertificates = NO;
    policy.validatesDomainName = YES;
    if ([policy evaluateServerTrust:serverTrust forDomain:host]) {
        return YES;
    }
    if (error) {
        *error = AFServerTrustError([NSString stringWithFormat:@"Server trust evaluation failed for host: %@", host]);
    }
    return NO;
}

@end

// MARK: - AFPinnedCertificatesTrustEvaluator

@interface AFPinnedCertificatesTrustEvaluator ()
@property (nonatomic, strong) NSSet<NSData *> *certificates;
@property (nonatomic, assign) BOOL validateCertificateChain;
@end

@implementation AFPinnedCertificatesTrustEvaluator

- (instancetype)initWithCertificates:(nullable NSSet<NSData *> *)certificates
              validateCertificateChain:(BOOL)validateCertificateChain {
    self = [super init];
    if (self) {
        _certificates = certificates ?: [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
        _validateCertificateChain = validateCertificateChain;
    }
    return self;
}

+ (instancetype)evaluatorWithPinnedCertificates {
    return [[self alloc] initWithCertificates:nil validateCertificateChain:YES];
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forHost:(NSString *)host error:(NSError **)error {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    policy.pinnedCertificates = self.certificates;
    policy.allowInvalidCertificates = !self.validateCertificateChain;
    policy.validatesDomainName = YES;
    if ([policy evaluateServerTrust:serverTrust forDomain:host]) {
        return YES;
    }
    if (error) {
        *error = AFServerTrustError([NSString stringWithFormat:@"Pinned certificate evaluation failed for host: %@", host]);
    }
    return NO;
}

@end

// MARK: - AFPublicKeysTrustEvaluator

@interface AFPublicKeysTrustEvaluator ()
@property (nonatomic, strong) NSSet<NSData *> *certificates;
@end

@implementation AFPublicKeysTrustEvaluator

- (instancetype)initWithCertificates:(nullable NSSet<NSData *> *)certificates {
    self = [super init];
    if (self) {
        _certificates = certificates ?: [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
    }
    return self;
}

+ (instancetype)evaluatorWithPinnedKeys {
    return [[self alloc] initWithCertificates:nil];
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forHost:(NSString *)host error:(NSError **)error {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    policy.pinnedCertificates = self.certificates;
    policy.allowInvalidCertificates = NO;
    policy.validatesDomainName = YES;
    if ([policy evaluateServerTrust:serverTrust forDomain:host]) {
        return YES;
    }
    if (error) {
        *error = AFServerTrustError([NSString stringWithFormat:@"Public key pinning evaluation failed for host: %@", host]);
    }
    return NO;
}

@end

// MARK: - AFDisabledTrustEvaluator

@implementation AFDisabledTrustEvaluator

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forHost:(NSString *)host error:(NSError **)error {
    return YES;
}

@end

// MARK: - AFCompositeTrustEvaluator

@interface AFCompositeTrustEvaluator ()
@property (nonatomic, copy) NSArray<id<AFServerTrustEvaluating>> *evaluators;
@end

@implementation AFCompositeTrustEvaluator

- (instancetype)initWithEvaluators:(NSArray<id<AFServerTrustEvaluating>> *)evaluators {
    self = [super init];
    if (self) {
        _evaluators = [evaluators copy];
    }
    return self;
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forHost:(NSString *)host error:(NSError **)error {
    for (id<AFServerTrustEvaluating> evaluator in self.evaluators) {
        if (![evaluator evaluateServerTrust:serverTrust forHost:host error:error]) {
            return NO;
        }
    }
    return YES;
}

@end

// MARK: - AFServerTrustManager

@implementation AFServerTrustManager

- (instancetype)initWithEvaluators:(NSDictionary<NSString *, id<AFServerTrustEvaluating>> *)evaluators {
    self = [super init];
    if (self) {
        _evaluators = [evaluators copy];
        _allHostsMustBeEvaluated = NO;
    }
    return self;
}

- (nullable id<AFServerTrustEvaluating>)evaluatorForHost:(NSString *)host {
    return self.evaluators[host];
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forHost:(NSString *)host error:(NSError **)error {
    id<AFServerTrustEvaluating> evaluator = self.evaluators[host];
    if (evaluator) {
        return [evaluator evaluateServerTrust:serverTrust forHost:host error:error];
    } else if (self.allHostsMustBeEvaluated) {
        if (error) {
            *error = [NSError errorWithDomain:AFServerTrustErrorDomain
                                         code:-2
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"No evaluator found for host: %@", host]}];
        }
        return NO;
    }
    return YES;
}

@end
