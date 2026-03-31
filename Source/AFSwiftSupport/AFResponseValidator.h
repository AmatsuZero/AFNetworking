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

NS_ASSUME_NONNULL_BEGIN

/// 响应验证错误域
FOUNDATION_EXPORT NSErrorDomain const AFResponseValidationErrorDomain NS_SWIFT_NAME(ResponseValidationErrorDomain);

/// 响应验证错误码
typedef NS_ERROR_ENUM(AFResponseValidationErrorDomain, AFResponseValidationErrorCode) {
    /// 状态码不在可接受范围内
    AFResponseValidationErrorUnacceptableStatusCode = -1000,
    /// Content-Type 不在可接受范围内
    AFResponseValidationErrorUnacceptableContentType = -1001,
    /// 自定义验证失败
    AFResponseValidationErrorCustomValidationFailed = -1002,
} NS_SWIFT_NAME(ResponseValidationError);

/// 验证错误 userInfo 中的实际状态码 key
FOUNDATION_EXPORT NSString *const AFResponseValidationErrorStatusCodeKey;
/// 验证错误 userInfo 中的可接受状态码集合 key
FOUNDATION_EXPORT NSString *const AFResponseValidationErrorAcceptableStatusCodesKey;
/// 验证错误 userInfo 中的实际 Content-Type key
FOUNDATION_EXPORT NSString *const AFResponseValidationErrorContentTypeKey;
/// 验证错误 userInfo 中的可接受 Content-Type 集合 key
FOUNDATION_EXPORT NSString *const AFResponseValidationErrorAcceptableContentTypesKey;

/**
 `AFResponseValidating` 协议定义响应验证器。
 对齐 Alamofire 的 `DataRequest.validate()` 链式验证设计。
 */
NS_SWIFT_NAME(ResponseValidating)
@protocol AFResponseValidating <NSObject>

/// 验证响应
/// @param request 原始请求
/// @param response HTTP 响应
/// @param data 响应数据
/// @return 验证失败时返回错误，成功返回 nil
- (nullable NSError *)validateRequest:(nullable NSURLRequest *)request
                             response:(NSHTTPURLResponse *)response
                                 data:(nullable NSData *)data;

@end

/**
 `AFStatusCodeValidator` 验证响应状态码是否在可接受范围内。
 默认可接受范围为 200-299。
 */
NS_SWIFT_NAME(StatusCodeValidator)
@interface AFStatusCodeValidator : NSObject <AFResponseValidating>

/// 可接受的状态码集合
@property (nonatomic, strong, readonly) NSIndexSet *acceptableStatusCodes;

/// 使用可接受状态码范围创建
/// @param statusCodes 可接受的状态码集合
- (instancetype)initWithAcceptableStatusCodes:(NSIndexSet *)statusCodes NS_DESIGNATED_INITIALIZER;

/// 默认验证器（200-299）
+ (instancetype)defaultValidator;

/// 使用状态码范围创建
+ (instancetype)validatorWithAcceptableStatusCodes:(NSIndexSet *)statusCodes;

@end

/**
 `AFContentTypeValidator` 验证响应 Content-Type 是否在可接受范围内。
 */
NS_SWIFT_NAME(ContentTypeValidator)
@interface AFContentTypeValidator : NSObject <AFResponseValidating>

/// 可接受的 Content-Type 集合
@property (nonatomic, strong, readonly) NSSet<NSString *> *acceptableContentTypes;

/// 使用可接受 Content-Type 集合创建
/// @param contentTypes 可接受的 Content-Type 集合
- (instancetype)initWithAcceptableContentTypes:(NSSet<NSString *> *)contentTypes NS_DESIGNATED_INITIALIZER;

/// 使用可接受 Content-Type 集合创建
+ (instancetype)validatorWithAcceptableContentTypes:(NSSet<NSString *> *)contentTypes;

@end

/**
 `AFBlockResponseValidator` 使用 block 实现自定义验证逻辑。
 */
NS_SWIFT_NAME(BlockResponseValidator)
@interface AFBlockResponseValidator : NSObject <AFResponseValidating>

/// 验证 block 类型
typedef NSError * _Nullable (^AFValidationBlock)(NSURLRequest * _Nullable request,
                                                  NSHTTPURLResponse *response,
                                                  NSData * _Nullable data);

/// 使用 block 创建验证器
/// @param block 验证逻辑 block
- (instancetype)initWithBlock:(AFValidationBlock)block NS_DESIGNATED_INITIALIZER;

+ (instancetype)validatorWithBlock:(AFValidationBlock)block;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END