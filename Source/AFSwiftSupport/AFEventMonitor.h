// AFEventMonitor.h
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

@class AFRequestContext;

NS_ASSUME_NONNULL_BEGIN

/**
 `AFEventMonitoring` 协议定义请求生命周期事件的观察接口。
 对齐 Alamofire 的 `EventMonitor` 协议。
 所有方法均为可选，实现者只需关注感兴趣的事件。
 */
NS_SWIFT_NAME(EventMonitoring)
@protocol AFEventMonitoring <NSObject>

@optional

/// 请求已创建
- (void)requestDidCreate:(AFRequestContext *)context;

/// 请求已被适配器修改
- (void)requestDidAdapt:(AFRequestContext *)context
         adaptedRequest:(NSURLRequest *)adaptedRequest;

/// 请求适配失败
- (void)requestDidFailToAdapt:(AFRequestContext *)context
                    withError:(NSError *)error;

/// 任务已恢复执行
- (void)requestDidResume:(AFRequestContext *)context;

/// 任务已暂停
- (void)requestDidSuspend:(AFRequestContext *)context;

/// 任务已取消
- (void)requestDidCancel:(AFRequestContext *)context;

/// 收到服务器响应
- (void)request:(AFRequestContext *)context
didReceiveResponse:(NSHTTPURLResponse *)response;

/// 收到响应数据
- (void)request:(AFRequestContext *)context
didReceiveData:(NSData *)data;

/// 上传进度更新
- (void)request:(AFRequestContext *)context
didUpdateUploadProgress:(NSProgress *)progress;

/// 下载进度更新
- (void)request:(AFRequestContext *)context
didUpdateDownloadProgress:(NSProgress *)progress;

/// 响应验证完成
- (void)request:(AFRequestContext *)context
didValidateWithResult:(nullable NSError *)validationError;

/// 响应序列化完成
- (void)request:(AFRequestContext *)context
didSerializeWithValue:(nullable id)value
          error:(nullable NSError *)error;

/// 请求将要重试
- (void)requestWillRetry:(AFRequestContext *)context;

/// 收集到任务指标
- (void)request:(AFRequestContext *)context
didCollectMetrics:(NSURLSessionTaskMetrics *)metrics API_AVAILABLE(ios(10.0), macos(10.12), tvos(10.0), watchos(3.0));

/// 请求已完成
- (void)requestDidFinish:(AFRequestContext *)context;

@end

/**
 `AFCompositeEventMonitor` 将多个事件监控器组合为一个，按顺序分发事件。
 */
NS_SWIFT_NAME(CompositeEventMonitor)
@interface AFCompositeEventMonitor : NSObject <AFEventMonitoring>

/// 所有子监控器
@property (nonatomic, copy, readonly) NSArray<id<AFEventMonitoring>> *monitors;

/// 使用监控器数组创建
/// @param monitors 子监控器数组
- (instancetype)initWithMonitors:(NSArray<id<AFEventMonitoring>> *)monitors NS_DESIGNATED_INITIALIZER;

+ (instancetype)monitorWithMonitors:(NSArray<id<AFEventMonitoring>> *)monitors;

@end

/**
 `AFClosureEventMonitor` 使用 block 实现事件监控，方便快速挂载调试逻辑。
 */
NS_SWIFT_NAME(ClosureEventMonitor)
@interface AFClosureEventMonitor : NSObject <AFEventMonitoring>

@property (nonatomic, copy, nullable) void (^requestDidCreateHandler)(AFRequestContext *context);
@property (nonatomic, copy, nullable) void (^requestDidResumeHandler)(AFRequestContext *context);
@property (nonatomic, copy, nullable) void (^requestDidSuspendHandler)(AFRequestContext *context);
@property (nonatomic, copy, nullable) void (^requestDidCancelHandler)(AFRequestContext *context);
@property (nonatomic, copy, nullable) void (^requestDidFinishHandler)(AFRequestContext *context);
@property (nonatomic, copy, nullable) void (^requestWillRetryHandler)(AFRequestContext *context);

@end

NS_ASSUME_NONNULL_END