// AFResponseValidator.h
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

/// 响应验证错误域
FOUNDATION_EXPORT NSErrorDomain const AFResponseValidationErrorDomain;

/// 响应验证错误码
typedef NS_ENUM(NSInteger, AFResponseValidationErrorCode) {
    /// 状态码不在可接受范围内
    AFResponseValidationErrorUnacceptableStatusCode = -1000,
    /// Content-Type 不在可接受范围内
    AFResponseValidationErrorUnacceptableContentType = -1001,
    /// 自定义验证失败
    AFResponseValidationErrorCustomValidationFailed = -1002,
};

/// 验证错误 userInfo key：实际状态码
FOUNDATION_EXPORT NSString * const AFResponseValidationErrorStatusCodeKey;
/// 验证错误 userInfo key：可接受状态码集合
FOUNDATION_EXPORT NSString * const AFResponseValidationErrorAcceptableStatusCodesKey;
/// 验证错误 userInfo key：实际 Content-Type
FOUNDATION_EXPORT NSString * const AFResponseValidationErrorContentTypeKey;
/// 验证错误 userInfo key：可接受 Content-Type 集合
FOUNDATION_EXPORT NSString * const AFResponseValidationErrorAcceptableContentTypesKey;

// MARK: - AFResponseValidator Protocol

/// 响应验证器协议
AF_SWIFT_SENDABLE
@protocol AFResponseValidator <NSObject>

/// 验证响应
/// @param request 原始请求
/// @param response HTTP 响应
/// @param data 响应数据
/// @return 验证失败时返回错误，成功返回 nil
- (nullable NSError *)validateRequest:(nullable NSURLRequest *)request
                             response:(NSHTTPURLResponse *)response
                                 data:(nullable NSData *)data;
@end

// MARK: - AFStatusCodeValidator

/// 验证响应状态码是否在可接受范围内
AF_SWIFT_SENDABLE
@interface AFStatusCodeValidator : NSObject <AFResponseValidator>

/// 可接受的状态码集合
@property (nonatomic, copy, readonly) NSIndexSet *acceptableStatusCodes;

/// 默认验证器（200-299）
+ (instancetype)defaultValidator;

/// 使用可接受状态码范围创建
- (instancetype)initWithAcceptableStatusCodes:(NSIndexSet *)statusCodes NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

// MARK: - AFContentTypeValidator

/// 验证响应 Content-Type 是否在可接受范围内。支持通配符匹配（如 "text/*"）。
AF_SWIFT_SENDABLE
@interface AFContentTypeValidator : NSObject <AFResponseValidator>

/// 可接受的 Content-Type 集合
@property (nonatomic, copy, readonly) NSSet<NSString *> *acceptableContentTypes;

/// 使用可接受 Content-Type 集合创建
- (instancetype)initWithAcceptableContentTypes:(NSSet<NSString *> *)contentTypes NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

// MARK: - AFBlockResponseValidator

/// 使用 block 实现自定义验证逻辑
AF_SWIFT_SENDABLE
@interface AFBlockResponseValidator : NSObject <AFResponseValidator>

/// 使用 block 创建验证器
- (instancetype)initWithBlock:(NSError * _Nullable (^)(NSURLRequest * _Nullable request,
                                                        NSHTTPURLResponse *response,
                                                        NSData * _Nullable data))block NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
