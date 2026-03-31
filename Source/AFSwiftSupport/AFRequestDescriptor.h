// AFRequestDescriptor.h
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
#import "AFHTTPMethod.h"
#import "AFHTTPHeaders.h"

@protocol AFURLRequestSerialization;
@protocol AFURLResponseSerialization;
@protocol AFRequestIntercepting;
@protocol AFResponseValidating;
@protocol AFEventMonitoring;

NS_ASSUME_NONNULL_BEGIN

/// 参数编码位置
typedef NS_ENUM(NSUInteger, AFParameterEncoding) {
    /// 自动：GET/HEAD/DELETE 放 URL，其他放 Body
    AFParameterEncodingAuto = 0,
    /// 强制 URL 查询参数编码
    AFParameterEncodingURLQuery,
    /// 强制 HTTP Body 编码
    AFParameterEncodingHTTPBody,
    /// JSON Body 编码
    AFParameterEncodingJSON,
    /// Property List Body 编码
    AFParameterEncodingPropertyList,
} NS_SWIFT_NAME(ParameterEncoding);

/**
 `AFRequestDescriptor` 描述单个请求的完整配置，是 request-centric 设计的核心。
 它承载了 URL、方法、参数、头、编码方式、序列化器、拦截器、验证器、监控器等所有单请求级别的配置。
 对齐 Alamofire 中 `Session.request(...)` 方法接受的参数集合。
 */
NS_SWIFT_NAME(RequestDescriptor)
@interface AFRequestDescriptor : NSObject <NSCopying>

/// 请求的 URL 字符串
@property (nonatomic, copy, readonly) NSString *URLString;

/// HTTP 方法
@property (nonatomic, copy, readonly) AFHTTPMethod method;

/// 请求参数，可以是 NSDictionary 或 NSArray
@property (nonatomic, strong, readonly, nullable) id parameters;

/// 参数编码方式
@property (nonatomic, assign, readonly) AFParameterEncoding encoding;

/// 请求头
@property (nonatomic, strong, readonly, nullable) AFHTTPHeaders *headers;

/// 请求超时时间，0 表示使用 manager 默认值
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/// 缓存策略，NSURLRequestUseProtocolCachePolicy 表示使用默认值
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;

/// 单请求级别的请求序列化器，nil 表示使用 manager 默认值
@property (nonatomic, strong, nullable) id<AFURLRequestSerialization> requestSerializer;

/// 单请求级别的响应序列化器，nil 表示使用 manager 默认值
@property (nonatomic, strong, nullable) id<AFURLResponseSerialization> responseSerializer;

/// 单请求级别的拦截器，nil 表示使用 session 默认值
@property (nonatomic, strong, nullable) id<AFRequestIntercepting> interceptor;

/// 单请求级别的响应验证器数组
@property (nonatomic, strong, nullable) NSArray<id<AFResponseValidating>> *validators;

/// 单请求级别的事件监控器数组
@property (nonatomic, strong, nullable) NSArray<id<AFEventMonitoring>> *eventMonitors;

/// 用户自定义上下文信息
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userInfo;

/// 创建请求描述
/// @param URLString 请求 URL 字符串
/// @param method HTTP 方法
/// @param parameters 请求参数
/// @param encoding 参数编码方式
/// @param headers 请求头
- (instancetype)initWithURLString:(NSString *)URLString
                           method:(AFHTTPMethod)method
                       parameters:(nullable id)parameters
                         encoding:(AFParameterEncoding)encoding
                          headers:(nullable AFHTTPHeaders *)headers NS_DESIGNATED_INITIALIZER;

/// 便利构造：GET 请求
+ (instancetype)GETWithURLString:(NSString *)URLString
                      parameters:(nullable id)parameters
                         headers:(nullable AFHTTPHeaders *)headers;

/// 便利构造：POST 请求
+ (instancetype)POSTWithURLString:(NSString *)URLString
                       parameters:(nullable id)parameters
                         headers:(nullable AFHTTPHeaders *)headers;

/// 便利构造：PUT 请求
+ (instancetype)PUTWithURLString:(NSString *)URLString
                      parameters:(nullable id)parameters
                         headers:(nullable AFHTTPHeaders *)headers;

/// 便利构造：DELETE 请求
+ (instancetype)DELETEWithURLString:(NSString *)URLString
                         parameters:(nullable id)parameters
                            headers:(nullable AFHTTPHeaders *)headers;

/// 便利构造：PATCH 请求
+ (instancetype)PATCHWithURLString:(NSString *)URLString
                        parameters:(nullable id)parameters
                           headers:(nullable AFHTTPHeaders *)headers;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END