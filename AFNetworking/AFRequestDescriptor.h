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
#import "AFCompatibilityMacros.h"
#import "AFHTTPHeader.h"
#import "AFResponseValidator.h"
#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"

NS_ASSUME_NONNULL_BEGIN

/// 参数编码方式
typedef NS_ENUM(NSInteger, AFParameterEncoding) {
    /// 根据 HTTP 方法自动选择（GET 用 URL，POST 用 body）
    AFParameterEncodingAuto = 0,
    /// URL 查询参数编码
    AFParameterEncodingURL,
    /// 强制 HTTP Body 编码
    AFParameterEncodingHTTPBody,
    /// JSON body 编码
    AFParameterEncodingJSON,
    /// Property List body 编码
    AFParameterEncodingPropertyList,
};

/// 描述单个请求的完整配置
AF_SWIFT_SENDABLE
@interface AFRequestDescriptor : NSObject <NSCopying>

/// 请求的 URL 字符串
@property (nonatomic, copy, readonly) NSString *urlString;
/// HTTP 方法（"GET"/"POST"/"PUT"/"DELETE"/"PATCH" 等）
@property (nonatomic, copy, readonly) NSString *method;
/// 请求参数
@property (nonatomic, strong, readonly, nullable) id parameters;
/// 参数编码方式
@property (nonatomic, readonly) AFParameterEncoding encoding;
/// 请求头
@property (nonatomic, strong, readonly, nullable) AFHTTPHeaders *headers;

/// 请求超时时间，0 表示使用 manager 默认值
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
/// 缓存策略
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
/// 单请求级别的请求序列化器
@property (nonatomic, strong, nullable) id<AFURLRequestSerialization> requestSerializer;
/// 单请求级别的响应序列化器
@property (nonatomic, strong, nullable) id<AFURLResponseSerialization> responseSerializer;
/// 单请求级别的响应验证器数组
@property (nonatomic, copy, nullable) NSArray<id<AFResponseValidator>> *validators;
/// 用户自定义上下文信息
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *userInfo;

- (instancetype)initWithURLString:(NSString *)urlString
                           method:(NSString *)method
                       parameters:(nullable id)parameters
                         encoding:(AFParameterEncoding)encoding
                          headers:(nullable AFHTTPHeaders *)headers NS_DESIGNATED_INITIALIZER;

// 便利工厂方法（小写）
+ (instancetype)getWithURLString:(NSString *)urlString parameters:(nullable id)parameters headers:(nullable AFHTTPHeaders *)headers;
+ (instancetype)postWithURLString:(NSString *)urlString parameters:(nullable id)parameters headers:(nullable AFHTTPHeaders *)headers;
+ (instancetype)putWithURLString:(NSString *)urlString parameters:(nullable id)parameters headers:(nullable AFHTTPHeaders *)headers;
+ (instancetype)deleteWithURLString:(NSString *)urlString parameters:(nullable id)parameters headers:(nullable AFHTTPHeaders *)headers;
+ (instancetype)patchWithURLString:(NSString *)urlString parameters:(nullable id)parameters headers:(nullable AFHTTPHeaders *)headers;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
