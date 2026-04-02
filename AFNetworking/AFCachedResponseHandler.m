// AFCachedResponseHandler.m
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

#import "AFCachedResponseHandler.h"

@interface AFResponseCacher ()
@property (nonatomic, assign) AFResponseCacherBehavior behavior;
@property (nonatomic, copy, nullable) NSCachedURLResponse * _Nullable (^modifyBlock)(NSURLSessionDataTask *, NSCachedURLResponse *);
@end

@implementation AFResponseCacher

- (instancetype)initWithBehavior:(AFResponseCacherBehavior)behavior
                     modifyBlock:(NSCachedURLResponse * _Nullable (^_Nullable)(NSURLSessionDataTask *, NSCachedURLResponse *))block {
    self = [super init];
    if (self) {
        _behavior = behavior;
        _modifyBlock = [block copy];
    }
    return self;
}

+ (instancetype)cacher {
    return [[self alloc] initWithBehavior:AFResponseCacherBehaviorCache modifyBlock:nil];
}

+ (instancetype)doNotCacher {
    return [[self alloc] initWithBehavior:AFResponseCacherBehaviorDoNotCache modifyBlock:nil];
}

+ (instancetype)modifyWithBlock:(NSCachedURLResponse * _Nullable (^)(NSURLSessionDataTask *, NSCachedURLResponse *))block {
    return [[self alloc] initWithBehavior:AFResponseCacherBehaviorModify modifyBlock:block];
}

- (nullable NSCachedURLResponse *)dataTask:(NSURLSessionDataTask *)task
                         willCacheResponse:(NSCachedURLResponse *)proposedResponse {
    switch (self.behavior) {
        case AFResponseCacherBehaviorCache:
            return proposedResponse;
        case AFResponseCacherBehaviorDoNotCache:
            return nil;
        case AFResponseCacherBehaviorModify:
            return self.modifyBlock ? self.modifyBlock(task, proposedResponse) : proposedResponse;
    }
}

@end
