// AFDataResponse.h
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

/**
 `AFDataResponse` 封装 data task 的统一响应结果。
 对齐 Alamofire 的 `DataResponse` 设计，收敛 request、response、data、value、error、metrics。
 */
NS_SWIFT_NAME(ObjCDataResponse)
@interface AFDataResponse : NSObject

/// 原始请求
@property (nonatomic, strong, readonly, nullable) NSURLRequest *request;

/// 服务器响应
@property (nonatomic, strong, readonly, nullable) NSHTTPURLResponse *response;

/// 原始响应数据
@property (nonatomic, strong, readonly, nullable) NSData *data;

/// 序列化后的值（JSON、String、Image 等）
@property (nonatomic, strong, readonly, nullable) id value;

/// 错误信息
@property (nonatomic, strong, readonly, nullable) NSError *error;

/// 任务指标
@property (nonatomic, strong, readonly, nullable) NSURLSessionTaskMetrics *metrics API_AVAILABLE(ios(10.0), macos(10.12), tvos(10.0), watchos(3.0));

/// 请求耗时（秒）
@property (nonatomic, assign, readonly) NSTimeInterval timeline;

/// 重试次数
@property (nonatomic, assign, readonly) NSUInteger retryCount;

/// 是否成功（error == nil）
@property (nonatomic, assign, readonly, getter=isSuccess) BOOL success;

/// 创建成功响应
- (instancetype)initWithRequest:(nullable NSURLRequest *)request
                       response:(nullable NSHTTPURLResponse *)response
                           data:(nullable NSData *)data
                          value:(nullable id)value
                          error:(nullable NSError *)error
                        metrics:(nullable NSURLSessionTaskMetrics *)metrics
                       timeline:(NSTimeInterval)timeline
                     retryCount:(NSUInteger)retryCount NS_DESIGNATED_INITIALIZER;

+ (instancetype)responseWithRequest:(nullable NSURLRequest *)request
                           response:(nullable NSHTTPURLResponse *)response
                               data:(nullable NSData *)data
                              value:(nullable id)value
                              error:(nullable NSError *)error
                            metrics:(nullable NSURLSessionTaskMetrics *)metrics
                           timeline:(NSTimeInterval)timeline
                         retryCount:(NSUInteger)retryCount;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END