// AFRequestInterceptor.h
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
#import "AFCompatibilityMacros.h"
#import "AFRetryResult.h"

NS_ASSUME_NONNULL_BEGIN

// MARK: - AFRequestAdapter Protocol

/// 请求适配器协议：在请求发送前修改 URLRequest
AF_SWIFT_SENDABLE
@protocol AFRequestAdapter <NSObject>

/// 适配请求
/// @param request 原始请求
/// @param completion 完成回调，传入修改后的请求或错误
- (void)adaptRequest:(NSURLRequest *)request
          completion:(void (^)(NSURLRequest * _Nullable adaptedRequest, NSError * _Nullable error))completion;

@end

// MARK: - AFRequestRetrier Protocol

/// 请求重试器协议：在请求失败后决定是否重试
AF_SWIFT_SENDABLE
@protocol AFRequestRetrier <NSObject>

/// 决定是否重试
/// @param request 失败的请求
/// @param error 失败错误
/// @param retryCount 当前已重试次数
/// @param completion 完成回调，传入重试结果
- (void)shouldRetryRequest:(NSURLRequest *)request
                 withError:(NSError *)error
                retryCount:(NSUInteger)retryCount
                completion:(void (^)(AFRetryResult *result))completion;

@end

// MARK: - AFRequestInterceptor

/// 组合适配器和重试器的拦截器
AF_SWIFT_SENDABLE
@interface AFRequestInterceptor : NSObject <AFRequestAdapter, AFRequestRetrier>

@property (nonatomic, strong, readonly, nullable) id<AFRequestAdapter> adapter;
@property (nonatomic, strong, readonly, nullable) id<AFRequestRetrier> retrier;

- (instancetype)initWithAdapter:(nullable id<AFRequestAdapter>)adapter
                        retrier:(nullable id<AFRequestRetrier>)retrier NS_DESIGNATED_INITIALIZER;

@end

// MARK: - AFBlockRequestAdapter

/// 使用 block 实现请求适配
AF_SWIFT_SENDABLE
@interface AFBlockRequestAdapter : NSObject <AFRequestAdapter>

- (instancetype)initWithBlock:(void (^)(NSURLRequest *request,
                                        void (^completion)(NSURLRequest * _Nullable, NSError * _Nullable)))block NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

// MARK: - AFBlockRequestRetrier

/// 使用 block 实现请求重试决策
AF_SWIFT_SENDABLE
@interface AFBlockRequestRetrier : NSObject <AFRequestRetrier>

- (instancetype)initWithBlock:(void (^)(NSURLRequest *request,
                                        NSError *error,
                                        NSUInteger retryCount,
                                        void (^completion)(AFRetryResult *)))block NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
