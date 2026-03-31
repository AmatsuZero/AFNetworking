// AFRequestInterceptor.m
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

#import "AFRequestInterceptor.h"

#pragma mark - AFRequestInterceptor

@implementation AFRequestInterceptor

- (instancetype)init {
    return [self initWithAdapter:nil retrier:nil];
}

- (instancetype)initWithAdapter:(nullable id<AFRequestAdapting>)adapter
                        retrier:(nullable id<AFRequestRetrying>)retrier {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _retrier = retrier;
    }
    return self;
}

+ (instancetype)interceptorWithAdapter:(nullable id<AFRequestAdapting>)adapter
                               retrier:(nullable id<AFRequestRetrying>)retrier {
    return [[self alloc] initWithAdapter:adapter retrier:retrier];
}

#pragma mark - AFRequestAdapting

- (void)adaptRequest:(NSURLRequest *)request
          completion:(void (^)(NSURLRequest * _Nullable, NSError * _Nullable))completion {
    if (self.adapter) {
        [self.adapter adaptRequest:request completion:completion];
    } else {
        completion(request, nil);
    }
}

#pragma mark - AFRequestRetrying

- (void)shouldRetryRequest:(NSURLRequest *)request
                 withError:(NSError *)error
                retryCount:(NSUInteger)retryCount
                completion:(void (^)(AFRetryResult, NSError * _Nullable))completion {
    if (self.retrier) {
        [self.retrier shouldRetryRequest:request withError:error retryCount:retryCount completion:completion];
    } else {
        completion(AFRetryResultDoNotRetry, nil);
    }
}

@end

#pragma mark - AFBlockRequestAdapter

@interface AFBlockRequestAdapter ()

@property (nonatomic, copy) AFAdaptHandler handler;

@end

@implementation AFBlockRequestAdapter

- (instancetype)initWithHandler:(AFAdaptHandler)handler {
    self = [super init];
    if (self) {
        _handler = [handler copy];
    }
    return self;
}

+ (instancetype)adapterWithHandler:(AFAdaptHandler)handler {
    return [[self alloc] initWithHandler:handler];
}

- (void)adaptRequest:(NSURLRequest *)request
          completion:(void (^)(NSURLRequest * _Nullable, NSError * _Nullable))completion {
    self.handler(request, completion);
}

@end

#pragma mark - AFBlockRequestRetrier

@interface AFBlockRequestRetrier ()

@property (nonatomic, copy) AFRetryHandler handler;

@end

@implementation AFBlockRequestRetrier

- (instancetype)initWithHandler:(AFRetryHandler)handler {
    self = [super init];
    if (self) {
        _handler = [handler copy];
    }
    return self;
}

+ (instancetype)retrierWithHandler:(AFRetryHandler)handler {
    return [[self alloc] initWithHandler:handler];
}

- (void)shouldRetryRequest:(NSURLRequest *)request
                 withError:(NSError *)error
                retryCount:(NSUInteger)retryCount
                completion:(void (^)(AFRetryResult, NSError * _Nullable))completion {
    self.handler(request, error, retryCount, completion);
}

@end