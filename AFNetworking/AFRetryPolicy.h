// AFRetryPolicy.h
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

#import <Foundation/Foundation.h>
#import "AFRequestInterceptor.h"
#import "AFCompatibilityMacros.h"

NS_ASSUME_NONNULL_BEGIN

/// 指数退避重试策略，对齐 Alamofire 的 `RetryPolicy`。
/// 重试延迟计算公式：delay = pow(exponentialBackoffBase, retryCount) * exponentialBackoffScale
AF_SWIFT_SENDABLE
@interface AFRetryPolicy : NSObject <AFRequestRetrier>

/// 最大重试次数，默认 2
@property (nonatomic, assign, readonly) NSUInteger retryLimit;

/// 指数退避底数，默认 2.0
@property (nonatomic, assign, readonly) double exponentialBackoffBase;

/// 指数退避缩放因子，默认 0.5
@property (nonatomic, assign, readonly) double exponentialBackoffScale;

/// 可重试的 HTTP 方法集合（默认：GET, HEAD, OPTIONS, PUT, DELETE, TRACE）
@property (nonatomic, copy, readonly) NSSet<NSString *> *retryableHTTPMethods;

/// 可重试的 HTTP 状态码集合（默认：408, 500, 502, 503, 504）
@property (nonatomic, copy, readonly) NSIndexSet *retryableHTTPStatusCodes;

/// 可重试的 URL 错误码集合（默认：常见网络错误码）
@property (nonatomic, copy, readonly) NSSet<NSNumber *> *retryableURLErrorCodes;

/// 使用默认配置创建
+ (instancetype)defaultPolicy;

/// 完整初始化
- (instancetype)initWithRetryLimit:(NSUInteger)retryLimit
              exponentialBackoffBase:(double)base
             exponentialBackoffScale:(double)scale
              retryableHTTPMethods:(NSSet<NSString *> *)methods
          retryableHTTPStatusCodes:(NSIndexSet *)statusCodes
            retryableURLErrorCodes:(NSSet<NSNumber *> *)errorCodes NS_DESIGNATED_INITIALIZER;

/// 计算重试延迟（秒）
- (NSTimeInterval)retryDelayForRetryCount:(NSUInteger)retryCount;

/// 判断是否应重试（不包含延迟逻辑）
- (BOOL)shouldRetryRequest:(NSURLRequest *)request
                  response:(nullable NSHTTPURLResponse *)response
                 withError:(NSError *)error;

@end

// MARK: - AFConnectionLostRetryPolicy

/// 连接丢失重试策略，仅在网络连接丢失时重试。
/// 对齐 Alamofire 的 `ConnectionLostRetryPolicy`。
AF_SWIFT_SENDABLE
@interface AFConnectionLostRetryPolicy : AFRetryPolicy

+ (instancetype)defaultPolicy;

- (instancetype)initWithRetryLimit:(NSUInteger)retryLimit
              exponentialBackoffBase:(double)base
             exponentialBackoffScale:(double)scale;

@end

NS_ASSUME_NONNULL_END
