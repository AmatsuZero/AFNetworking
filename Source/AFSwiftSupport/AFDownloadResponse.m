// AFDownloadResponse.m
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

#import "AFDownloadResponse.h"

@implementation AFDownloadResponse

- (instancetype)initWithRequest:(nullable NSURLRequest *)request
                       response:(nullable NSHTTPURLResponse *)response
                        fileURL:(nullable NSURL *)fileURL
                     resumeData:(nullable NSData *)resumeData
                          value:(nullable id)value
                          error:(nullable NSError *)error
                        metrics:(nullable NSURLSessionTaskMetrics *)metrics
                       timeline:(NSTimeInterval)timeline
                     retryCount:(NSUInteger)retryCount {
    self = [super init];
    if (self) {
        _request = request;
        _response = response;
        _fileURL = fileURL;
        _resumeData = resumeData;
        _value = value;
        _error = error;
        _metrics = metrics;
        _timeline = timeline;
        _retryCount = retryCount;
    }
    return self;
}

+ (instancetype)responseWithRequest:(nullable NSURLRequest *)request
                           response:(nullable NSHTTPURLResponse *)response
                            fileURL:(nullable NSURL *)fileURL
                         resumeData:(nullable NSData *)resumeData
                              value:(nullable id)value
                              error:(nullable NSError *)error
                            metrics:(nullable NSURLSessionTaskMetrics *)metrics
                           timeline:(NSTimeInterval)timeline
                         retryCount:(NSUInteger)retryCount {
    return [[self alloc] initWithRequest:request
                                response:response
                                 fileURL:fileURL
                              resumeData:resumeData
                                   value:value
                                   error:error
                                 metrics:metrics
                                timeline:timeline
                              retryCount:retryCount];
}

- (BOOL)isSuccess {
    return self.error == nil;
}

- (NSString *)description {
    NSString *status = self.response ? [NSString stringWithFormat:@"%ld", (long)self.response.statusCode] : @"nil";
    return [NSString stringWithFormat:@"<%@: %p, status=%@, success=%@, fileURL=%@, retryCount=%lu>",
            NSStringFromClass([self class]), self,
            status,
            self.isSuccess ? @"YES" : @"NO",
            self.fileURL,
            (unsigned long)self.retryCount];
}

@end