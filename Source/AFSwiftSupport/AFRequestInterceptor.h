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

NS_ASSUME_NONNULL_BEGIN

/// 重试结果
typedef NS_ENUM(NSUInteger, AFRetryResult) {
    /// 执行重试
    AFRetryResultRetry = 0,
    /// 不重试，使用原始错误
    AFRetryResultDoNotRetry,
    /// 不重试，使用指定错误
    AFRetryResultDoNotRetryWithError,
} NS_SWIFT_NAME(RetryResult);

/**
 `AFRequestAdapting` 协议定义请求适配器，在请求发送前修改 `NSURLRequest`。
 对齐 Alamofire 的 `RequestAdapter` 协议。
 */
NS_SWIFT_NAME(RequestAdapting)
@protocol AFRequestAdapting <NSObject>

/// 适配请求
/// @param request 原始请求
/// @param completion 完成回调，传入修改后的请求或错误
- (void)adaptRequest:(NSURLRequest *)request
          completion:(void (^)(NSURLRequest * _Nullable adaptedRequest, NSError * _Nullable error))completion;

@end

/**
 `AFRequestRetrying` 协议定义请求重试器，在请求失败后决定是否重试。
 对齐 Alamofire 的 `RequestRetrier` 协议。
 */
NS_SWIFT_NAME(RequestRetrying)
@protocol AFRequestRetrying <NSObject>

/// 决定是否重试
/// @param request 失败的请求
/// @param error 失败错误
/// @param retryCount 当前已重试次数
/// @param completion 完成回调，传入重试结果和可选的替代错误
- (void)shouldRetryRequest:(NSURLRequest *)request
                 withError:(NSError *)error
                retryCount:(NSUInteger)retryCount
                completion:(void (^)(AFRetryResult result, NSError * _Nullable retryError))completion;

@end

/**
 `AFRequestIntercepting` 协议组合了适配器和重试器，对齐 Alamofire 的 `RequestInterceptor`。
 */
NS_SWIFT_NAME(RequestIntercepting)
@protocol AFRequestIntercepting <AFRequestAdapting, AFRequestRetrying>

@end

/**
 `AFRequestInterceptor` 是 `AFRequestIntercepting` 的默认组合实现。
 可以分别设置 adapter 和 retrier，也可以同时设置。
 */
NS_SWIFT_NAME(Interceptor)
@interface AFRequestInterceptor : NSObject <AFRequestIntercepting>

/// 请求适配器
@property (nonatomic, strong, nullable) id<AFRequestAdapting> adapter;

/// 请求重试器
@property (nonatomic, strong, nullable) id<AFRequestRetrying> retrier;

/// 使用适配器和重试器创建拦截器
/// @param adapter 请求适配器
/// @param retrier 请求重试器
- (instancetype)initWithAdapter:(nullable id<AFRequestAdapting>)adapter
                        retrier:(nullable id<AFRequestRetrying>)retrier NS_DESIGNATED_INITIALIZER;

/// 便利构造
+ (instancetype)interceptorWithAdapter:(nullable id<AFRequestAdapting>)adapter
                               retrier:(nullable id<AFRequestRetrying>)retrier;

@end

/**
 `AFBlockRequestAdapter` 使用 block 实现请求适配。
 */
NS_SWIFT_NAME(BlockRequestAdapter)
@interface AFBlockRequestAdapter : NSObject <AFRequestAdapting>

/// 适配 block 类型
typedef void (^AFAdaptHandler)(NSURLRequest *request,
                               void (^completion)(NSURLRequest * _Nullable, NSError * _Nullable));

/// 使用 block 创建适配器
/// @param handler 适配处理 block
- (instancetype)initWithHandler:(AFAdaptHandler)handler NS_DESIGNATED_INITIALIZER;

+ (instancetype)adapterWithHandler:(AFAdaptHandler)handler;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/**
 `AFBlockRequestRetrier` 使用 block 实现请求重试决策。
 */
NS_SWIFT_NAME(BlockRequestRetrier)
@interface AFBlockRequestRetrier : NSObject <AFRequestRetrying>

/// 重试决策 block 类型
typedef void (^AFRetryHandler)(NSURLRequest *request,
                               NSError *error,
                               NSUInteger retryCount,
                               void (^completion)(AFRetryResult, NSError * _Nullable));

/// 使用 block 创建重试器
/// @param handler 重试决策处理 block
- (instancetype)initWithHandler:(AFRetryHandler)handler NS_DESIGNATED_INITIALIZER;

+ (instancetype)retrierWithHandler:(AFRetryHandler)handler;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END