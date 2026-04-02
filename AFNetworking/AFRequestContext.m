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
#import <os/lock.h>

@interface AFRequestContext () {
    os_unfair_lock _lock;
}
@end

@implementation AFRequestContext

- (instancetype)initWithDescriptor:(AFRequestDescriptor *)descriptor {
    self = [super init];
    if (self) {
        _descriptor = descriptor;
        _state = AFRequestStateInitialized;
        _createdAt = [NSDate date];
        _identifier = [[NSUUID UUID] UUIDString];
        _lock = OS_UNFAIR_LOCK_INIT;
    }
    return self;
}

- (nullable NSData *)data {
    os_unfair_lock_lock(&_lock);
    NSData *data = self.mutableData ? [NSData dataWithData:self.mutableData] : nil;
    os_unfair_lock_unlock(&_lock);
    return data;
}

- (void)resetResponseState {
    os_unfair_lock_lock(&_lock);
    self.mutableData = nil;
    self.response = nil;
    self.fileURL = nil;
    self.serializedObject = nil;
    self.error = nil;
    self.metrics = nil;
    os_unfair_lock_unlock(&_lock);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<AFRequestContext: %@, state: %ld, url: %@>",
            self.identifier, (long)self.state, self.descriptor.urlString];
}

@end
