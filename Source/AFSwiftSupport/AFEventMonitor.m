// AFEventMonitor.m
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

#import "AFEventMonitor.h"
#import "AFRequestContext.h"

#pragma mark - 宏：向所有子监控器分发事件

#define AF_DISPATCH_EVENT(sel, ...) \
    for (id<AFEventMonitoring> monitor in self.monitors) { \
        if ([monitor respondsToSelector:@selector(sel)]) { \
            [monitor sel __VA_ARGS__]; \
        } \
    }

#pragma mark - AFCompositeEventMonitor

@implementation AFCompositeEventMonitor

- (instancetype)init {
    return [self initWithMonitors:@[]];
}

- (instancetype)initWithMonitors:(NSArray<id<AFEventMonitoring>> *)monitors {
    self = [super init];
    if (self) {
        _monitors = [monitors copy];
    }
    return self;
}

+ (instancetype)monitorWithMonitors:(NSArray<id<AFEventMonitoring>> *)monitors {
    return [[self alloc] initWithMonitors:monitors];
}

- (void)requestDidCreate:(AFRequestContext *)context {
    AF_DISPATCH_EVENT(requestDidCreate:, context);
}

- (void)requestDidAdapt:(AFRequestContext *)context adaptedRequest:(NSURLRequest *)adaptedRequest {
    for (id<AFEventMonitoring> monitor in self.monitors) {
        if ([monitor respondsToSelector:@selector(requestDidAdapt:adaptedRequest:)]) {
            [monitor requestDidAdapt:context adaptedRequest:adaptedRequest];
        }
    }
}

- (void)requestDidFailToAdapt:(AFRequestContext *)context withError:(NSError *)error {
    for (id<AFEventMonitoring> monitor in self.monitors) {
        if ([monitor respondsToSelector:@selector(requestDidFailToAdapt:withError:)]) {
            [monitor requestDidFailToAdapt:context withError:error];
        }
    }
}

- (void)requestDidResume:(AFRequestContext *)context {
    AF_DISPATCH_EVENT(requestDidResume:, context);
}

- (void)requestDidSuspend:(AFRequestContext *)context {
    AF_DISPATCH_EVENT(requestDidSuspend:, context);
}

- (void)requestDidCancel:(AFRequestContext *)context {
    AF_DISPATCH_EVENT(requestDidCancel:, context);
}

- (void)request:(AFRequestContext *)context didReceiveResponse:(NSHTTPURLResponse *)response {
    for (id<AFEventMonitoring> monitor in self.monitors) {
        if ([monitor respondsToSelector:@selector(request:didReceiveResponse:)]) {
            [monitor request:context didReceiveResponse:response];
        }
    }
}

- (void)request:(AFRequestContext *)context didReceiveData:(NSData *)data {
    for (id<AFEventMonitoring> monitor in self.monitors) {
        if ([monitor respondsToSelector:@selector(request:didReceiveData:)]) {
            [monitor request:context didReceiveData:data];
        }
    }
}

- (void)request:(AFRequestContext *)context didUpdateUploadProgress:(NSProgress *)progress {
    for (id<AFEventMonitoring> monitor in self.monitors) {
        if ([monitor respondsToSelector:@selector(request:didUpdateUploadProgress:)]) {
            [monitor request:context didUpdateUploadProgress:progress];
        }
    }
}

- (void)request:(AFRequestContext *)context didUpdateDownloadProgress:(NSProgress *)progress {
    for (id<AFEventMonitoring> monitor in self.monitors) {
        if ([monitor respondsToSelector:@selector(request:didUpdateDownloadProgress:)]) {
            [monitor request:context didUpdateDownloadProgress:progress];
        }
    }
}

- (void)request:(AFRequestContext *)context didValidateWithResult:(nullable NSError *)validationError {
    for (id<AFEventMonitoring> monitor in self.monitors) {
        if ([monitor respondsToSelector:@selector(request:didValidateWithResult:)]) {
            [monitor request:context didValidateWithResult:validationError];
        }
    }
}

- (void)request:(AFRequestContext *)context didSerializeWithValue:(nullable id)value error:(nullable NSError *)error {
    for (id<AFEventMonitoring> monitor in self.monitors) {
        if ([monitor respondsToSelector:@selector(request:didSerializeWithValue:error:)]) {
            [monitor request:context didSerializeWithValue:value error:error];
        }
    }
}

- (void)requestWillRetry:(AFRequestContext *)context {
    AF_DISPATCH_EVENT(requestWillRetry:, context);
}

- (void)request:(AFRequestContext *)context didCollectMetrics:(NSURLSessionTaskMetrics *)metrics {
    for (id<AFEventMonitoring> monitor in self.monitors) {
        if ([monitor respondsToSelector:@selector(request:didCollectMetrics:)]) {
            [monitor request:context didCollectMetrics:metrics];
        }
    }
}

- (void)requestDidFinish:(AFRequestContext *)context {
    AF_DISPATCH_EVENT(requestDidFinish:, context);
}

@end

#pragma mark - AFClosureEventMonitor

@implementation AFClosureEventMonitor

- (void)requestDidCreate:(AFRequestContext *)context {
    if (self.requestDidCreateHandler) {
        self.requestDidCreateHandler(context);
    }
}

- (void)requestDidResume:(AFRequestContext *)context {
    if (self.requestDidResumeHandler) {
        self.requestDidResumeHandler(context);
    }
}

- (void)requestDidSuspend:(AFRequestContext *)context {
    if (self.requestDidSuspendHandler) {
        self.requestDidSuspendHandler(context);
    }
}

- (void)requestDidCancel:(AFRequestContext *)context {
    if (self.requestDidCancelHandler) {
        self.requestDidCancelHandler(context);
    }
}

- (void)requestDidFinish:(AFRequestContext *)context {
    if (self.requestDidFinishHandler) {
        self.requestDidFinishHandler(context);
    }
}

- (void)requestWillRetry:(AFRequestContext *)context {
    if (self.requestWillRetryHandler) {
        self.requestWillRetryHandler(context);
    }
}

@end