// AFRedirectHandler.m
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

#import "AFRedirectHandler.h"

@interface AFRedirector ()
@property (nonatomic, assign) AFRedirectorBehavior behavior;
@property (nonatomic, copy, nullable) NSURLRequest * _Nullable (^modifyBlock)(NSURLSessionTask *, NSURLRequest *, NSHTTPURLResponse *);
@end

@implementation AFRedirector

- (instancetype)initWithBehavior:(AFRedirectorBehavior)behavior
                     modifyBlock:(NSURLRequest * _Nullable (^_Nullable)(NSURLSessionTask *, NSURLRequest *, NSHTTPURLResponse *))block {
    self = [super init];
    if (self) {
        _behavior = behavior;
        _modifyBlock = [block copy];
    }
    return self;
}

+ (instancetype)follower {
    return [[self alloc] initWithBehavior:AFRedirectorBehaviorFollow modifyBlock:nil];
}

+ (instancetype)doNotFollower {
    return [[self alloc] initWithBehavior:AFRedirectorBehaviorDoNotFollow modifyBlock:nil];
}

+ (instancetype)modifyWithBlock:(NSURLRequest * _Nullable (^)(NSURLSessionTask *, NSURLRequest *, NSHTTPURLResponse *))block {
    return [[self alloc] initWithBehavior:AFRedirectorBehaviorModify modifyBlock:block];
}

- (nullable NSURLRequest *)task:(NSURLSessionTask *)task
              willBeRedirectedTo:(NSURLRequest *)request
                     forResponse:(NSHTTPURLResponse *)response {
    switch (self.behavior) {
        case AFRedirectorBehaviorFollow:
            return request;
        case AFRedirectorBehaviorDoNotFollow:
            return nil;
        case AFRedirectorBehaviorModify:
            return self.modifyBlock ? self.modifyBlock(task, request, response) : request;
    }
}

@end
