// AFRequestContext.h
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
#import "AFRequestDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// 请求上下文的状态
typedef NS_ENUM(NSUInteger, AFRequestState) {
    /// 已初始化，尚未发起
    AFRequestStateInitialized = 0,
    /// 已恢复（正在执行）
    AFRequestStateResumed,
    /// 已暂停
    AFRequestStateSuspended,
    /// 已取消
    AFRequestStateCancelled,
    /// 已完成
    AFRequestStateFinished,
} NS_SWIFT_NAME(RequestState);

/**
 `AFRequestContext` 是单个请求的运行时上下文，关联 `NSURLSessionTask` 与请求生命周期中的所有状态。
 它是 request-centric 管线的核心内部对象，Swift 层的 `Request` 类型将持有并操作此上下文。
 */
NS_SWIFT_NAME(RequestContext)
@interface AFRequestContext : NSObject

/// 请求描述（不可变配置）
@property (nonatomic, strong, readonly) AFRequestDescriptor *descriptor;

/// 当前关联的 NSURLSessionTask
@property (nonatomic, strong, nullable) NSURLSessionTask *task;

/// 当前请求状态
@property (nonatomic, assign) AFRequestState state;

/// 原始请求（经过 adapter 修改后的最终请求）
@property (nonatomic, strong, nullable) NSURLRequest *currentRequest;

/// 初始请求（adapter 修改前的原始请求）
@property (nonatomic, strong, nullable) NSURLRequest *initialRequest;

/// 服务器响应
@property (nonatomic, strong, nullable) NSHTTPURLResponse *response;

/// 收集到的响应数据（data task 场景）
@property (nonatomic, strong, nullable) NSMutableData *mutableData;

/// 下载文件的本地 URL（download task 场景）
@property (nonatomic, strong, nullable) NSURL *fileURL;

/// 序列化后的响应对象
@property (nonatomic, strong, nullable) id serializedObject;

/// 请求过程中产生的错误
@property (nonatomic, strong, nullable) NSError *error;

/// 任务指标
@property (nonatomic, strong, nullable) NSURLSessionTaskMetrics *metrics API_AVAILABLE(ios(10.0), macos(10.12), tvos(10.0), watchos(3.0));

/// 当前重试次数
@property (nonatomic, assign) NSUInteger retryCount;

/// 最大重试次数（0 表示不重试）
@property (nonatomic, assign) NSUInteger maxRetryCount;

/// 请求创建时间
@property (nonatomic, strong, readonly) NSDate *createdAt;

/// 唯一标识符
@property (nonatomic, copy, readonly) NSString *identifier;

/// 使用请求描述创建上下文
/// @param descriptor 请求描述
- (instancetype)initWithDescriptor:(AFRequestDescriptor *)descriptor NS_DESIGNATED_INITIALIZER;

/// 获取已收集的响应数据（不可变副本）
@property (nonatomic, copy, readonly, nullable) NSData *data;

/// 重置响应数据（用于重试场景）
- (void)resetResponseState;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END