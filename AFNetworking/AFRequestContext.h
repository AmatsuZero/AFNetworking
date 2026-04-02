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

/// 请求状态
typedef NS_ENUM(NSInteger, AFRequestState) {
    AFRequestStateInitialized,
    AFRequestStateResumed,
    AFRequestStateSuspended,
    AFRequestStateCancelled,
    AFRequestStateFinished,
};

/// 单个请求的运行时上下文
@interface AFRequestContext : NSObject

/// 请求描述（不可变配置）
@property (nonatomic, strong, readonly) AFRequestDescriptor *descriptor;

/// 当前关联的 URLSessionTask
@property (nullable, nonatomic, strong) NSURLSessionTask *task;
/// 请求状态
@property (nonatomic, assign) AFRequestState state;
/// 原始请求（经过 adapter 修改后的最终请求）
@property (nullable, nonatomic, strong) NSURLRequest *currentRequest;
/// 初始请求
@property (nullable, nonatomic, strong) NSURLRequest *initialRequest;
/// 服务器响应
@property (nullable, nonatomic, strong) NSHTTPURLResponse *response;
/// 收集到的响应数据
@property (nullable, nonatomic, strong) NSMutableData *mutableData;
/// 下载文件的本地 URL
@property (nullable, nonatomic, strong) NSURL *fileURL;
/// 序列化后的响应对象
@property (nullable, nonatomic, strong) id serializedObject;
/// 请求过程中产生的错误
@property (nullable, nonatomic, strong) NSError *error;
/// 任务指标
@property (nullable, nonatomic, strong) NSURLSessionTaskMetrics *metrics;
/// 当前重试次数
@property (nonatomic, assign) NSUInteger retryCount;
/// 最大重试次数
@property (nonatomic, assign) NSUInteger maxRetryCount;
/// 请求创建时间
@property (nonatomic, strong, readonly) NSDate *createdAt;
/// 唯一标识符
@property (nonatomic, copy, readonly) NSString *identifier;

- (instancetype)initWithDescriptor:(AFRequestDescriptor *)descriptor NS_DESIGNATED_INITIALIZER;

/// 获取已收集的响应数据（线程安全）
- (nullable NSData *)data;

/// 重置响应数据（用于重试场景，线程安全）
- (void)resetResponseState;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
