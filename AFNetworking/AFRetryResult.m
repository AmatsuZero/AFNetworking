// AFRetryResult.m
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

#import "AFRetryResult.h"

@interface AFRetryResult ()
@property (nonatomic, assign) AFRetryResultType type;
@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, strong, nullable) NSError *error;
@end

@implementation AFRetryResult

- (instancetype)initWithType:(AFRetryResultType)type delay:(NSTimeInterval)delay error:(nullable NSError *)error {
    self = [super init];
    if (self) {
        _type = type;
        _delay = delay;
        _error = error;
    }
    return self;
}

+ (instancetype)retry {
    return [[self alloc] initWithType:AFRetryResultTypeRetry delay:0 error:nil];
}

+ (instancetype)retryWithDelay:(NSTimeInterval)delay {
    return [[self alloc] initWithType:AFRetryResultTypeRetryWithDelay delay:delay error:nil];
}

+ (instancetype)doNotRetry {
    return [[self alloc] initWithType:AFRetryResultTypeDoNotRetry delay:0 error:nil];
}

+ (instancetype)doNotRetryWithError:(NSError *)error {
    return [[self alloc] initWithType:AFRetryResultTypeDoNotRetryWithError delay:0 error:error];
}

- (NSString *)description {
    switch (self.type) {
        case AFRetryResultTypeRetry: return @"<AFRetryResult: retry>";
        case AFRetryResultTypeRetryWithDelay: return [NSString stringWithFormat:@"<AFRetryResult: retry with delay %.2fs>", self.delay];
        case AFRetryResultTypeDoNotRetry: return @"<AFRetryResult: doNotRetry>";
        case AFRetryResultTypeDoNotRetryWithError: return [NSString stringWithFormat:@"<AFRetryResult: doNotRetry, error: %@>", self.error.localizedDescription];
    }
}

@end
