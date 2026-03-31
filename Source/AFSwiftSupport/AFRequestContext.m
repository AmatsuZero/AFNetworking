// AFRequestContext.m
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

#import "AFRequestContext.h"

@interface AFRequestContext ()

@property (nonatomic, strong, readwrite) AFRequestDescriptor *descriptor;
@property (nonatomic, strong, readwrite) NSDate *createdAt;
@property (nonatomic, copy, readwrite) NSString *identifier;

@end

@implementation AFRequestContext

- (instancetype)initWithDescriptor:(AFRequestDescriptor *)descriptor {
    self = [super init];
    if (self) {
        _descriptor = descriptor;
        _state = AFRequestStateInitialized;
        _retryCount = 0;
        _maxRetryCount = 0;
        _createdAt = [NSDate date];
        _identifier = [[NSUUID UUID] UUIDString];
        _mutableData = nil;
    }
    return self;
}

- (nullable NSData *)data {
    @synchronized (self) {
        return [self.mutableData copy];
    }
}

- (void)resetResponseState {
    @synchronized (self) {
        self.mutableData = nil;
        self.response = nil;
        self.fileURL = nil;
        self.serializedObject = nil;
        self.error = nil;
        self.metrics = nil;
    }
}

#pragma mark - NSObject

- (NSString *)description {
    NSString *stateString;
    switch (self.state) {
        case AFRequestStateInitialized: stateString = @"initialized"; break;
        case AFRequestStateResumed:     stateString = @"resumed"; break;
        case AFRequestStateSuspended:   stateString = @"suspended"; break;
        case AFRequestStateCancelled:   stateString = @"cancelled"; break;
        case AFRequestStateFinished:    stateString = @"finished"; break;
    }
    return [NSString stringWithFormat:@"<%@: %p, id=%@, state=%@, retryCount=%lu, method=%@, URL=%@>",
            NSStringFromClass([self class]), self,
            self.identifier, stateString,
            (unsigned long)self.retryCount,
            self.descriptor.method, self.descriptor.URLString];
}

@end