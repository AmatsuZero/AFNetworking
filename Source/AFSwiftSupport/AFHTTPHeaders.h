// AFHTTPHeaders.h
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
 `AFHTTPHeader` 表示单个 HTTP 头字段的名值对。
 对齐 Alamofire 的 `HTTPHeader` 设计。
 */
NS_SWIFT_NAME(HTTPHeader)
@interface AFHTTPHeader : NSObject <NSCopying, NSSecureCoding>

/// 头字段名称
@property (nonatomic, copy, readonly) NSString *name;

/// 头字段值
@property (nonatomic, copy, readonly) NSString *value;

/// 使用名称和值创建头字段
/// @param name 头字段名称
/// @param value 头字段值
- (instancetype)initWithName:(NSString *)name value:(NSString *)value NS_DESIGNATED_INITIALIZER;

/// 使用名称和值创建头字段
/// @param name 头字段名称
/// @param value 头字段值
+ (instancetype)headerWithName:(NSString *)name value:(NSString *)value;

#pragma mark - 常用头字段便利构造

/// 创建 Accept 头
/// @param value Accept 值，如 "application/json"
+ (instancetype)acceptWithValue:(NSString *)value;

/// 创建 Content-Type 头
/// @param value Content-Type 值，如 "application/json"
+ (instancetype)contentTypeWithValue:(NSString *)value;

/// 创建 Authorization 头
/// @param value Authorization 值，如 "Bearer token"
+ (instancetype)authorizationWithValue:(NSString *)value;

/// 创建 Bearer Token Authorization 头
/// @param token Bearer token 字符串
+ (instancetype)authorizationWithBearerToken:(NSString *)token;

/// 创建 Basic Authorization 头
/// @param username 用户名
/// @param password 密码
+ (instancetype)authorizationWithUsername:(NSString *)username
                                password:(NSString *)password;

/// 创建 User-Agent 头
/// @param value User-Agent 值
+ (instancetype)userAgentWithValue:(NSString *)value;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/**
 `AFHTTPHeaders` 是一个有序的 HTTP 头字段集合，保持插入顺序并支持按名称去重。
 对齐 Alamofire 的 `HTTPHeaders` 设计。
 */
NS_SWIFT_NAME(HTTPHeaders)
@interface AFHTTPHeaders : NSObject <NSCopying, NSSecureCoding, NSFastEnumeration>

/// 所有头字段的有序数组
@property (nonatomic, copy, readonly) NSArray<AFHTTPHeader *> *headers;

/// 以字典形式返回所有头字段（同名取最后一个值）
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *dictionary;

/// 创建空的头集合
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// 从头字段数组创建
/// @param headers 头字段数组，同名字段后者覆盖前者
- (instancetype)initWithHeaders:(NSArray<AFHTTPHeader *> *)headers;

/// 从字典创建
/// @param dictionary 头字段字典
- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)dictionary;

/// 从头字段数组创建
/// @param headers 头字段数组
+ (instancetype)headersWithHeaders:(NSArray<AFHTTPHeader *> *)headers;

/// 从字典创建
/// @param dictionary 头字段字典
+ (instancetype)headersWithDictionary:(NSDictionary<NSString *, NSString *> *)dictionary;

/// 默认头集合，包含 Accept-Encoding、Accept-Language 和 User-Agent
+ (instancetype)defaultHeaders;

#pragma mark - 增删改查

/// 添加或更新头字段（同名覆盖）
/// @param header 要添加的头字段
- (void)addHeader:(AFHTTPHeader *)header;

/// 添加或更新头字段
/// @param name 头字段名称
/// @param value 头字段值
- (void)addName:(NSString *)name value:(NSString *)value;

/// 移除指定名称的头字段
/// @param name 要移除的头字段名称
- (void)removeHeaderForName:(NSString *)name;

/// 按名称查找头字段值
/// @param name 头字段名称
/// @return 头字段值，不存在时返回 nil
- (nullable NSString *)valueForName:(NSString *)name;

/// 按名称查找头字段
/// @param name 头字段名称
/// @return 头字段对象，不存在时返回 nil
- (nullable AFHTTPHeader *)headerForName:(NSString *)name;

/// 对指定 NSMutableURLRequest 应用所有头字段
/// @param request 要应用头字段的请求
- (void)applyToURLRequest:(NSMutableURLRequest *)request;

/// 头字段数量
@property (nonatomic, readonly) NSUInteger count;

@end

NS_ASSUME_NONNULL_END