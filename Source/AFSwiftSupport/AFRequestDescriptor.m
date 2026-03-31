// AFRequestDescriptor.m
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

#import "AFRequestDescriptor.h"

@implementation AFRequestDescriptor

- (instancetype)initWithURLString:(NSString *)URLString
                           method:(AFHTTPMethod)method
                       parameters:(nullable id)parameters
                         encoding:(AFParameterEncoding)encoding
                          headers:(nullable AFHTTPHeaders *)headers {
    self = [super init];
    if (self) {
        _URLString = [URLString copy];
        _method = [method copy];
        _parameters = parameters;
        _encoding = encoding;
        _headers = [headers copy];
        _timeoutInterval = 0;
        _cachePolicy = NSURLRequestUseProtocolCachePolicy;
    }
    return self;
}

+ (instancetype)GETWithURLString:(NSString *)URLString
                      parameters:(nullable id)parameters
                         headers:(nullable AFHTTPHeaders *)headers {
    return [[self alloc] initWithURLString:URLString
                                    method:AFHTTPMethodGET
                                parameters:parameters
                                  encoding:AFParameterEncodingAuto
                                   headers:headers];
}

+ (instancetype)POSTWithURLString:(NSString *)URLString
                       parameters:(nullable id)parameters
                          headers:(nullable AFHTTPHeaders *)headers {
    return [[self alloc] initWithURLString:URLString
                                    method:AFHTTPMethodPOST
                                parameters:parameters
                                  encoding:AFParameterEncodingAuto
                                   headers:headers];
}

+ (instancetype)PUTWithURLString:(NSString *)URLString
                      parameters:(nullable id)parameters
                         headers:(nullable AFHTTPHeaders *)headers {
    return [[self alloc] initWithURLString:URLString
                                    method:AFHTTPMethodPUT
                                parameters:parameters
                                  encoding:AFParameterEncodingAuto
                                   headers:headers];
}

+ (instancetype)DELETEWithURLString:(NSString *)URLString
                         parameters:(nullable id)parameters
                            headers:(nullable AFHTTPHeaders *)headers {
    return [[self alloc] initWithURLString:URLString
                                    method:AFHTTPMethodDELETE
                                parameters:parameters
                                  encoding:AFParameterEncodingAuto
                                   headers:headers];
}

+ (instancetype)PATCHWithURLString:(NSString *)URLString
                        parameters:(nullable id)parameters
                           headers:(nullable AFHTTPHeaders *)headers {
    return [[self alloc] initWithURLString:URLString
                                    method:AFHTTPMethodPATCH
                                parameters:parameters
                                  encoding:AFParameterEncodingAuto
                                   headers:headers];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFRequestDescriptor *copy = [[AFRequestDescriptor alloc] initWithURLString:self.URLString
                                                                        method:self.method
                                                                    parameters:self.parameters
                                                                      encoding:self.encoding
                                                                       headers:self.headers];
    copy.timeoutInterval = self.timeoutInterval;
    copy.cachePolicy = self.cachePolicy;
    copy.requestSerializer = self.requestSerializer;
    copy.responseSerializer = self.responseSerializer;
    copy.interceptor = self.interceptor;
    copy.validators = [self.validators copy];
    copy.eventMonitors = [self.eventMonitors copy];
    copy.userInfo = [self.userInfo copy];
    return copy;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, method=%@, URL=%@>",
            NSStringFromClass([self class]), self, self.method, self.URLString];
}

@end