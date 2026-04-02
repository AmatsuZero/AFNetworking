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
#import "AFRequestContext.h"

NS_ASSUME_NONNULL_BEGIN

// MARK: - AFEventMonitorDelegate Protocol

/// 请求生命周期事件 delegate 协议
@protocol AFEventMonitorDelegate <NSObject>
@optional

/// 请求已创建
- (void)requestDidCreate:(AFRequestContext *)context;
/// 请求已被适配器修改
- (void)request:(AFRequestContext *)context didAdaptToURLRequest:(NSURLRequest *)request;
/// 请求适配失败
- (void)request:(AFRequestContext *)context didFailAdaptationWithError:(NSError *)error;
/// 任务已恢复执行
- (void)requestDidResume:(AFRequestContext *)context;
/// 任务已暂停
- (void)requestDidSuspend:(AFRequestContext *)context;
/// 任务已取消
- (void)requestDidCancel:(AFRequestContext *)context;
/// 收到服务器响应
- (void)request:(AFRequestContext *)context didReceiveResponse:(NSHTTPURLResponse *)response;
/// 收到响应数据
- (void)request:(AFRequestContext *)context didReceiveData:(NSData *)data;
/// 上传进度更新
- (void)request:(AFRequestContext *)context didUpdateUploadProgress:(NSProgress *)progress;
/// 下载进度更新
- (void)request:(AFRequestContext *)context didUpdateDownloadProgress:(NSProgress *)progress;
/// 响应验证完成
- (void)request:(AFRequestContext *)context didValidateWithError:(nullable NSError *)error;
/// 响应序列化完成
- (void)request:(AFRequestContext *)context didSerializeResult:(nullable id)result error:(nullable NSError *)error;
/// 请求将要重试
- (void)requestWillRetry:(AFRequestContext *)context;
/// 收集到任务指标
- (void)request:(AFRequestContext *)context didCollectMetrics:(NSURLSessionTaskMetrics *)metrics;
/// 请求已完成
- (void)requestDidFinish:(AFRequestContext *)context;

@end

// MARK: - AFEventMonitorCenter

/// 事件监控中心：管理多个 delegate，分发请求生命周期事件
@interface AFEventMonitorCenter : NSObject

+ (instancetype)sharedCenter;

- (void)addDelegate:(id<AFEventMonitorDelegate>)delegate;
- (void)removeDelegate:(id<AFEventMonitorDelegate>)delegate;

// 事件通知方法（内部使用）
- (void)notifyRequestDidCreate:(AFRequestContext *)context;
- (void)notifyRequest:(AFRequestContext *)context didAdaptToURLRequest:(NSURLRequest *)request;
- (void)notifyRequest:(AFRequestContext *)context didFailAdaptationWithError:(NSError *)error;
- (void)notifyRequestDidResume:(AFRequestContext *)context;
- (void)notifyRequestDidSuspend:(AFRequestContext *)context;
- (void)notifyRequestDidCancel:(AFRequestContext *)context;
- (void)notifyRequest:(AFRequestContext *)context didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)notifyRequest:(AFRequestContext *)context didReceiveData:(NSData *)data;
- (void)notifyRequest:(AFRequestContext *)context didUpdateUploadProgress:(NSProgress *)progress;
- (void)notifyRequest:(AFRequestContext *)context didUpdateDownloadProgress:(NSProgress *)progress;
- (void)notifyRequest:(AFRequestContext *)context didValidateWithError:(nullable NSError *)error;
- (void)notifyRequest:(AFRequestContext *)context didSerializeResult:(nullable id)result error:(nullable NSError *)error;
- (void)notifyRequestWillRetry:(AFRequestContext *)context;
- (void)notifyRequest:(AFRequestContext *)context didCollectMetrics:(NSURLSessionTaskMetrics *)metrics;
- (void)notifyRequestDidFinish:(AFRequestContext *)context;

@end

NS_ASSUME_NONNULL_END
