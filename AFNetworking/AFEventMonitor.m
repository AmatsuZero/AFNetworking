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
#import <os/lock.h>

@interface AFEventMonitorCenter () {
    os_unfair_lock _lock;
}
@property (nonatomic, strong) NSHashTable<id<AFEventMonitorDelegate>> *delegates;
@end

@implementation AFEventMonitorCenter

+ (instancetype)sharedCenter {
    static AFEventMonitorCenter *center;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[AFEventMonitorCenter alloc] init];
    });
    return center;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _delegates = [NSHashTable weakObjectsHashTable];
        _lock = OS_UNFAIR_LOCK_INIT;
    }
    return self;
}

- (void)addDelegate:(id<AFEventMonitorDelegate>)delegate {
    os_unfair_lock_lock(&_lock);
    [self.delegates addObject:delegate];
    os_unfair_lock_unlock(&_lock);
}

- (void)removeDelegate:(id<AFEventMonitorDelegate>)delegate {
    os_unfair_lock_lock(&_lock);
    [self.delegates removeObject:delegate];
    os_unfair_lock_unlock(&_lock);
}

- (NSArray<id<AFEventMonitorDelegate>> *)allDelegates {
    os_unfair_lock_lock(&_lock);
    NSArray *result = self.delegates.allObjects;
    os_unfair_lock_unlock(&_lock);
    return result;
}

// MARK: - Notify Methods

#define AF_NOTIFY_DELEGATES(sel, ...) \
    for (id<AFEventMonitorDelegate> delegate in [self allDelegates]) { \
        if ([delegate respondsToSelector:@selector(sel)]) { \
            [delegate __VA_ARGS__]; \
        } \
    }

- (void)notifyRequestDidCreate:(AFRequestContext *)context {
    AF_NOTIFY_DELEGATES(requestDidCreate:, requestDidCreate:context)
}

- (void)notifyRequest:(AFRequestContext *)context didAdaptToURLRequest:(NSURLRequest *)request {
    AF_NOTIFY_DELEGATES(request:didAdaptToURLRequest:, request:context didAdaptToURLRequest:request)
}

- (void)notifyRequest:(AFRequestContext *)context didFailAdaptationWithError:(NSError *)error {
    AF_NOTIFY_DELEGATES(request:didFailAdaptationWithError:, request:context didFailAdaptationWithError:error)
}

- (void)notifyRequestDidResume:(AFRequestContext *)context {
    AF_NOTIFY_DELEGATES(requestDidResume:, requestDidResume:context)
}

- (void)notifyRequestDidSuspend:(AFRequestContext *)context {
    AF_NOTIFY_DELEGATES(requestDidSuspend:, requestDidSuspend:context)
}

- (void)notifyRequestDidCancel:(AFRequestContext *)context {
    AF_NOTIFY_DELEGATES(requestDidCancel:, requestDidCancel:context)
}

- (void)notifyRequest:(AFRequestContext *)context didReceiveResponse:(NSHTTPURLResponse *)response {
    AF_NOTIFY_DELEGATES(request:didReceiveResponse:, request:context didReceiveResponse:response)
}

- (void)notifyRequest:(AFRequestContext *)context didReceiveData:(NSData *)data {
    AF_NOTIFY_DELEGATES(request:didReceiveData:, request:context didReceiveData:data)
}

- (void)notifyRequest:(AFRequestContext *)context didUpdateUploadProgress:(NSProgress *)progress {
    AF_NOTIFY_DELEGATES(request:didUpdateUploadProgress:, request:context didUpdateUploadProgress:progress)
}

- (void)notifyRequest:(AFRequestContext *)context didUpdateDownloadProgress:(NSProgress *)progress {
    AF_NOTIFY_DELEGATES(request:didUpdateDownloadProgress:, request:context didUpdateDownloadProgress:progress)
}

- (void)notifyRequest:(AFRequestContext *)context didValidateWithError:(nullable NSError *)error {
    AF_NOTIFY_DELEGATES(request:didValidateWithError:, request:context didValidateWithError:error)
}

- (void)notifyRequest:(AFRequestContext *)context didSerializeResult:(nullable id)result error:(nullable NSError *)error {
    AF_NOTIFY_DELEGATES(request:didSerializeResult:error:, request:context didSerializeResult:result error:error)
}

- (void)notifyRequestWillRetry:(AFRequestContext *)context {
    AF_NOTIFY_DELEGATES(requestWillRetry:, requestWillRetry:context)
}

- (void)notifyRequest:(AFRequestContext *)context didCollectMetrics:(NSURLSessionTaskMetrics *)metrics {
    AF_NOTIFY_DELEGATES(request:didCollectMetrics:, request:context didCollectMetrics:metrics)
}

- (void)notifyRequestDidFinish:(AFRequestContext *)context {
    AF_NOTIFY_DELEGATES(requestDidFinish:, requestDidFinish:context)
}

#undef AF_NOTIFY_DELEGATES

@end
