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

NSErrorDomain const AFResponseValidationErrorDomain = @"com.alamofire.error.validation";

NSString * const AFResponseValidationErrorStatusCodeKey = @"com.alamofire.validation.statusCode";
NSString * const AFResponseValidationErrorAcceptableStatusCodesKey = @"com.alamofire.validation.acceptableStatusCodes";
NSString * const AFResponseValidationErrorContentTypeKey = @"com.alamofire.validation.contentType";
NSString * const AFResponseValidationErrorAcceptableContentTypesKey = @"com.alamofire.validation.acceptableContentTypes";

// MARK: - AFStatusCodeValidator

@implementation AFStatusCodeValidator

+ (instancetype)defaultValidator {
    return [[self alloc] initWithAcceptableStatusCodes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)]];
}

- (instancetype)initWithAcceptableStatusCodes:(NSIndexSet *)statusCodes {
    self = [super init];
    if (self) {
        _acceptableStatusCodes = [statusCodes copy];
    }
    return self;
}

- (nullable NSError *)validateRequest:(nullable NSURLRequest *)request
                             response:(NSHTTPURLResponse *)response
                                 data:(nullable NSData *)data {
    if ([self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode]) {
        return nil;
    }

    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Response status code was unacceptable: %ld.", (long)response.statusCode],
        AFResponseValidationErrorStatusCodeKey: @(response.statusCode),
        AFResponseValidationErrorAcceptableStatusCodesKey: self.acceptableStatusCodes,
    };
    return [NSError errorWithDomain:AFResponseValidationErrorDomain
                               code:AFResponseValidationErrorUnacceptableStatusCode
                           userInfo:userInfo];
}

@end

// MARK: - AFContentTypeValidator

@implementation AFContentTypeValidator

- (instancetype)initWithAcceptableContentTypes:(NSSet<NSString *> *)contentTypes {
    self = [super init];
    if (self) {
        _acceptableContentTypes = [contentTypes copy];
    }
    return self;
}

- (nullable NSError *)validateRequest:(nullable NSURLRequest *)request
                             response:(NSHTTPURLResponse *)response
                                 data:(nullable NSData *)data {
    NSString *contentType = response.allHeaderFields[@"Content-Type"];
    if (!contentType) {
        if (data && data.length > 0) {
            return [self makeErrorWithActualContentType:@"nil"];
        }
        return nil;
    }

    NSString *mimeType = [[contentType componentsSeparatedByString:@";"].firstObject
                          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!mimeType) {
        mimeType = contentType;
    }

    for (NSString *acceptable in self.acceptableContentTypes) {
        if ([acceptable isEqualToString:mimeType]) {
            return nil;
        }
        // 支持通配符匹配，如 "text/*"
        if ([acceptable hasSuffix:@"/*"]) {
            NSString *prefix = [acceptable substringToIndex:acceptable.length - 2];
            if ([mimeType hasPrefix:prefix]) {
                return nil;
            }
        }
        if ([acceptable isEqualToString:@"*/*"]) {
            return nil;
        }
    }

    return [self makeErrorWithActualContentType:mimeType];
}

- (NSError *)makeErrorWithActualContentType:(NSString *)actualContentType {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Response Content-Type \"%@\" does not match any acceptable Content-Type: %@.", actualContentType, self.acceptableContentTypes],
        AFResponseValidationErrorContentTypeKey: actualContentType,
        AFResponseValidationErrorAcceptableContentTypesKey: self.acceptableContentTypes,
    };
    return [NSError errorWithDomain:AFResponseValidationErrorDomain
                               code:AFResponseValidationErrorUnacceptableContentType
                           userInfo:userInfo];
}

@end

// MARK: - AFBlockResponseValidator

@interface AFBlockResponseValidator ()
@property (nonatomic, copy) NSError * _Nullable (^validationBlock)(NSURLRequest * _Nullable, NSHTTPURLResponse *, NSData * _Nullable);
@end

@implementation AFBlockResponseValidator

- (instancetype)initWithBlock:(NSError * _Nullable (^)(NSURLRequest * _Nullable, NSHTTPURLResponse *, NSData * _Nullable))block {
    self = [super init];
    if (self) {
        _validationBlock = [block copy];
    }
    return self;
}

- (nullable NSError *)validateRequest:(nullable NSURLRequest *)request
                             response:(NSHTTPURLResponse *)response
                                 data:(nullable NSData *)data {
    return self.validationBlock(request, response, data);
}

@end
