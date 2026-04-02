// AFHTTPHeader.h
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

NS_ASSUME_NONNULL_BEGIN

/// 单个 HTTP 头字段的名值对
AF_SWIFT_SENDABLE
@interface AFHTTPHeader : NSObject <NSCopying>

/// 头字段名称
@property (nonatomic, copy, readonly) NSString *name;
/// 头字段值
@property (nonatomic, copy, readonly) NSString *value;

- (instancetype)initWithName:(NSString *)name value:(NSString *)value NS_DESIGNATED_INITIALIZER;
+ (instancetype)headerWithName:(NSString *)name value:(NSString *)value;

// MARK: - 常用头字段便利构造

+ (instancetype)accept:(NSString *)value;
+ (instancetype)contentType:(NSString *)value;
+ (instancetype)authorization:(NSString *)value;
+ (instancetype)userAgent:(NSString *)value;
+ (instancetype)bearerAuthorization:(NSString *)token;
+ (instancetype)basicAuthorizationWithUsername:(NSString *)username password:(NSString *)password;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

// MARK: - AFHTTPHeaders

/// 有序 HTTP 头字段集合。保持插入顺序并支持按名称去重（case-insensitive）。
AF_SWIFT_SENDABLE
@interface AFHTTPHeaders : NSObject <NSFastEnumeration, NSCopying>

/// 以字典形式返回所有头字段（同名取最后一个值）
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *dictionary;

/// 头字段数量
@property (nonatomic, readonly) NSUInteger count;

/// 所有头字段的有序数组
@property (nonatomic, copy, readonly) NSArray<AFHTTPHeader *> *allHeaders;

/// 默认头集合（Accept-Encoding + Accept-Language）
+ (instancetype)defaultHeaders;

/// 创建空的头集合
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// 从头字段数组创建（同名字段后者覆盖前者）
- (instancetype)initWithHeaders:(NSArray<AFHTTPHeader *> *)headers;

/// 从字典创建
- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)dictionary;

/// 添加或更新头字段（同名覆盖）
- (void)addHeader:(AFHTTPHeader *)header;

/// 添加或更新头字段
- (void)addName:(NSString *)name value:(NSString *)value;

/// 移除指定名称的头字段（case-insensitive）
- (void)removeHeaderForName:(NSString *)name;

/// 按名称查找头字段值（case-insensitive）
- (nullable NSString *)valueForHeaderName:(NSString *)name;

/// 按名称查找头字段（case-insensitive）
- (nullable AFHTTPHeader *)headerForName:(NSString *)name;

/// 对指定 URLRequest 应用所有头字段
- (void)applyToRequest:(NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
