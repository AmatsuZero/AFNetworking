// AFResponseValidator.m
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

#import "AFResponseValidator.h"

NSErrorDomain const AFResponseValidationErrorDomain = @"com.alamofire.afnetworking.validation";

NSString *const AFResponseValidationErrorStatusCodeKey = @"AFResponseValidationErrorStatusCode";
NSString *const AFResponseValidationErrorAcceptableStatusCodesKey = @"AFResponseValidationErrorAcceptableStatusCodes";
NSString *const AFResponseValidationErrorContentTypeKey = @"AFResponseValidationErrorContentType";
NSString *const AFResponseValidationErrorAcceptableContentTypesKey = @"AFResponseValidationErrorAcceptableContentTypes";

#pragma mark - AFStatusCodeValidator

@implementation AFStatusCodeValidator

- (instancetype)init {
    return [self initWithAcceptableStatusCodes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)]];
}

- (instancetype)initWithAcceptableStatusCodes:(NSIndexSet *)statusCodes {
    self = [super init];
    if (self) {
        _acceptableStatusCodes = [statusCodes copy];
    }
    return self;
}

+ (instancetype)defaultValidator {
    return [[self alloc] init];
}

+ (instancetype)validatorWithAcceptableStatusCodes:(NSIndexSet *)statusCodes {
    return [[self alloc] initWithAcceptableStatusCodes:statusCodes];
}

- (nullable NSError *)validateRequest:(nullable NSURLRequest *)request
                             response:(NSHTTPURLResponse *)response
                                 data:(nullable NSData *)data {
    if ([self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode]) {
        return nil;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"Response status code was unacceptable: %ld",
                                           (long)response.statusCode];
    userInfo[AFResponseValidationErrorStatusCodeKey] = @(response.statusCode);
    userInfo[AFResponseValidationErrorAcceptableStatusCodesKey] = self.acceptableStatusCodes;
    if (response.URL) {
        userInfo[NSURLErrorFailingURLErrorKey] = response.URL;
    }

    return [NSError errorWithDomain:AFResponseValidationErrorDomain
                               code:AFResponseValidationErrorUnacceptableStatusCode
                           userInfo:userInfo];
}

@end

#pragma mark - AFContentTypeValidator

@implementation AFContentTypeValidator

- (instancetype)init {
    return [self initWithAcceptableContentTypes:[NSSet set]];
}

- (instancetype)initWithAcceptableContentTypes:(NSSet<NSString *> *)contentTypes {
    self = [super init];
    if (self) {
        _acceptableContentTypes = [contentTypes copy];
    }
    return self;
}

+ (instancetype)validatorWithAcceptableContentTypes:(NSSet<NSString *> *)contentTypes {
    return [[self alloc] initWithAcceptableContentTypes:contentTypes];
}

- (nullable NSError *)validateRequest:(nullable NSURLRequest *)request
                             response:(NSHTTPURLResponse *)response
                                 data:(nullable NSData *)data {
    if (self.acceptableContentTypes.count == 0) {
        return nil;
    }

    NSString *contentType = response.MIMEType;
    if (!contentType) {
        // 无 Content-Type 时，如果有数据则视为验证失败
        if (data.length > 0) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            userInfo[NSLocalizedDescriptionKey] = @"Response Content-Type was missing";
            if (response.URL) {
                userInfo[NSURLErrorFailingURLErrorKey] = response.URL;
            }
            return [NSError errorWithDomain:AFResponseValidationErrorDomain
                                       code:AFResponseValidationErrorUnacceptableContentType
                                   userInfo:userInfo];
        }
        return nil;
    }

    if ([self.acceptableContentTypes containsObject:contentType]) {
        return nil;
    }

    // 检查是否匹配通配符，如 "text/*"
    for (NSString *acceptable in self.acceptableContentTypes) {
        if ([acceptable hasSuffix:@"/*"]) {
            NSString *prefix = [acceptable substringToIndex:acceptable.length - 1];
            if ([contentType hasPrefix:prefix]) {
                return nil;
            }
        }
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:
                                           @"Response Content-Type \"%@\" does not match any acceptable Content-Type",
                                           contentType];
    userInfo[AFResponseValidationErrorContentTypeKey] = contentType;
    userInfo[AFResponseValidationErrorAcceptableContentTypesKey] = self.acceptableContentTypes;
    if (response.URL) {
        userInfo[NSURLErrorFailingURLErrorKey] = response.URL;
    }

    return [NSError errorWithDomain:AFResponseValidationErrorDomain
                               code:AFResponseValidationErrorUnacceptableContentType
                           userInfo:userInfo];
}

@end

#pragma mark - AFBlockResponseValidator

@interface AFBlockResponseValidator ()

@property (nonatomic, copy) AFValidationBlock block;

@end

@implementation AFBlockResponseValidator

- (instancetype)initWithBlock:(AFValidationBlock)block {
    self = [super init];
    if (self) {
        _block = [block copy];
    }
    return self;
}

+ (instancetype)validatorWithBlock:(AFValidationBlock)block {
    return [[self alloc] initWithBlock:block];
}

- (nullable NSError *)validateRequest:(nullable NSURLRequest *)request
                             response:(NSHTTPURLResponse *)response
                                 data:(nullable NSData *)data {
    return self.block(request, response, data);
}

@end