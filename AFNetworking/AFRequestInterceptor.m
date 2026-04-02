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

// MARK: - AFRequestInterceptor

@implementation AFRequestInterceptor

- (instancetype)init {
    return [self initWithAdapter:nil retrier:nil];
}

- (instancetype)initWithAdapter:(nullable id<AFRequestAdapter>)adapter
                        retrier:(nullable id<AFRequestRetrier>)retrier {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _retrier = retrier;
    }
    return self;
}

- (void)adaptRequest:(NSURLRequest *)request
          completion:(void (^)(NSURLRequest * _Nullable, NSError * _Nullable))completion {
    if (self.adapter) {
        [self.adapter adaptRequest:request completion:completion];
    } else {
        completion(request, nil);
    }
}

- (void)shouldRetryRequest:(NSURLRequest *)request
                 withError:(NSError *)error
                retryCount:(NSUInteger)retryCount
                completion:(void (^)(AFRetryResult *))completion {
    if (self.retrier) {
        [self.retrier shouldRetryRequest:request withError:error retryCount:retryCount completion:completion];
    } else {
        completion([AFRetryResult doNotRetry]);
    }
}

@end

// MARK: - AFBlockRequestAdapter

@interface AFBlockRequestAdapter ()
@property (nonatomic, copy) void (^adapterBlock)(NSURLRequest *, void (^)(NSURLRequest * _Nullable, NSError * _Nullable));
@end

@implementation AFBlockRequestAdapter

- (instancetype)initWithBlock:(void (^)(NSURLRequest *, void (^)(NSURLRequest * _Nullable, NSError * _Nullable)))block {
    self = [super init];
    if (self) {
        _adapterBlock = [block copy];
    }
    return self;
}

- (void)adaptRequest:(NSURLRequest *)request
          completion:(void (^)(NSURLRequest * _Nullable, NSError * _Nullable))completion {
    self.adapterBlock(request, completion);
}

@end

// MARK: - AFBlockRequestRetrier

@interface AFBlockRequestRetrier ()
@property (nonatomic, copy) void (^retrierBlock)(NSURLRequest *, NSError *, NSUInteger, void (^)(AFRetryResult *));
@end

@implementation AFBlockRequestRetrier

- (instancetype)initWithBlock:(void (^)(NSURLRequest *, NSError *, NSUInteger, void (^)(AFRetryResult *)))block {
    self = [super init];
    if (self) {
        _retrierBlock = [block copy];
    }
    return self;
}

- (void)shouldRetryRequest:(NSURLRequest *)request
                 withError:(NSError *)error
                retryCount:(NSUInteger)retryCount
                completion:(void (^)(AFRetryResult *))completion {
    self.retrierBlock(request, error, retryCount, completion);
}

@end
