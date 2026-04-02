// AFRetryPolicy.m
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

#import "AFRetryPolicy.h"
#import "AFRetryResult.h"

// 默认可重试的 HTTP 方法（幂等方法）
static NSSet<NSString *> *AFDefaultRetryableHTTPMethods(void) {
    return [NSSet setWithArray:@[@"DELETE", @"GET", @"HEAD", @"OPTIONS", @"PUT", @"TRACE"]];
}

// 默认可重试的 HTTP 状态码
static NSIndexSet *AFDefaultRetryableHTTPStatusCodes(void) {
    NSMutableIndexSet *codes = [NSMutableIndexSet indexSet];
    [codes addIndex:408]; // Request Timeout
    [codes addIndex:500]; // Internal Server Error
    [codes addIndex:502]; // Bad Gateway
    [codes addIndex:503]; // Service Unavailable
    [codes addIndex:504]; // Gateway Timeout
    return [codes copy];
}

// 默认可重试的 URL 错误码
static NSSet<NSNumber *> *AFDefaultRetryableURLErrorCodes(void) {
    return [NSSet setWithArray:@[
        @(NSURLErrorTimedOut),
        @(NSURLErrorCannotFindHost),
        @(NSURLErrorCannotConnectToHost),
        @(NSURLErrorDNSLookupFailed),
        @(NSURLErrorNetworkConnectionLost),
        @(NSURLErrorNotConnectedToInternet),
        @(NSURLErrorInternationalRoamingOff),
        @(NSURLErrorSecureConnectionFailed),
    ]];
}

// 连接丢失相关的错误码
static NSSet<NSNumber *> *AFConnectionLostURLErrorCodes(void) {
    return [NSSet setWithArray:@[
        @(NSURLErrorNetworkConnectionLost),
    ]];
}

@implementation AFRetryPolicy

+ (instancetype)defaultPolicy {
    return [[self alloc] initWithRetryLimit:2
                      exponentialBackoffBase:2.0
                     exponentialBackoffScale:0.5
                      retryableHTTPMethods:AFDefaultRetryableHTTPMethods()
                  retryableHTTPStatusCodes:AFDefaultRetryableHTTPStatusCodes()
                    retryableURLErrorCodes:AFDefaultRetryableURLErrorCodes()];
}

- (instancetype)init {
    return [self initWithRetryLimit:2
               exponentialBackoffBase:2.0
              exponentialBackoffScale:0.5
               retryableHTTPMethods:AFDefaultRetryableHTTPMethods()
           retryableHTTPStatusCodes:AFDefaultRetryableHTTPStatusCodes()
             retryableURLErrorCodes:AFDefaultRetryableURLErrorCodes()];
}

- (instancetype)initWithRetryLimit:(NSUInteger)retryLimit
              exponentialBackoffBase:(double)base
             exponentialBackoffScale:(double)scale
              retryableHTTPMethods:(NSSet<NSString *> *)methods
          retryableHTTPStatusCodes:(NSIndexSet *)statusCodes
            retryableURLErrorCodes:(NSSet<NSNumber *> *)errorCodes {
    self = [super init];
    if (self) {
        _retryLimit = retryLimit;
        _exponentialBackoffBase = base;
        _exponentialBackoffScale = scale;
        _retryableHTTPMethods = [methods copy];
        _retryableHTTPStatusCodes = [statusCodes copy];
        _retryableURLErrorCodes = [errorCodes copy];
    }
    return self;
}

- (NSTimeInterval)retryDelayForRetryCount:(NSUInteger)retryCount {
    return pow(self.exponentialBackoffBase, (double)retryCount) * self.exponentialBackoffScale;
}

- (BOOL)shouldRetryRequest:(NSURLRequest *)request
                  response:(NSHTTPURLResponse *)response
                 withError:(NSError *)error {
    // 检查 HTTP 方法是否在可重试集合中
    NSString *method = request.HTTPMethod.uppercaseString;
    if (![self.retryableHTTPMethods containsObject:method]) {
        return NO;
    }

    // 检查 HTTP 状态码
    if (response && [self.retryableHTTPStatusCodes containsIndex:(NSUInteger)response.statusCode]) {
        return YES;
    }

    // 检查 URL 错误码
    if ([error.domain isEqualToString:NSURLErrorDomain] &&
        [self.retryableURLErrorCodes containsObject:@(error.code)]) {
        return YES;
    }

    return NO;
}

#pragma mark - AFRequestRetrier

- (void)shouldRetryRequest:(NSURLRequest *)request
                 withError:(NSError *)error
                retryCount:(NSUInteger)retryCount
                completion:(void (^)(AFRetryResult *))completion {
    if (retryCount < self.retryLimit && [self shouldRetryRequest:request response:nil withError:error]) {
        NSTimeInterval delay = [self retryDelayForRetryCount:retryCount];
        completion([AFRetryResult retryWithDelay:delay]);
    } else {
        completion([AFRetryResult doNotRetry]);
    }
}

@end

// MARK: - AFConnectionLostRetryPolicy

@implementation AFConnectionLostRetryPolicy

+ (instancetype)defaultPolicy {
    return [[self alloc] initWithRetryLimit:2
                      exponentialBackoffBase:2.0
                     exponentialBackoffScale:0.5];
}

- (instancetype)initWithRetryLimit:(NSUInteger)retryLimit
              exponentialBackoffBase:(double)base
             exponentialBackoffScale:(double)scale {
    return [super initWithRetryLimit:retryLimit
                exponentialBackoffBase:base
               exponentialBackoffScale:scale
                retryableHTTPMethods:AFDefaultRetryableHTTPMethods()
            retryableHTTPStatusCodes:[NSIndexSet indexSet]
              retryableURLErrorCodes:AFConnectionLostURLErrorCodes()];
}

@end
