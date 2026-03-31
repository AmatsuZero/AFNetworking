// AFHTTPMethod.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// HTTP 请求方法的类型安全封装，对齐 Alamofire 的 HTTPMethod 设计。
typedef NSString *AFHTTPMethod NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(HTTPMethod);

/// HTTP GET 方法
FOUNDATION_EXPORT AFHTTPMethod const AFHTTPMethodGET;
/// HTTP HEAD 方法
FOUNDATION_EXPORT AFHTTPMethod const AFHTTPMethodHEAD;
/// HTTP POST 方法
FOUNDATION_EXPORT AFHTTPMethod const AFHTTPMethodPOST;
/// HTTP PUT 方法
FOUNDATION_EXPORT AFHTTPMethod const AFHTTPMethodPUT;
/// HTTP PATCH 方法
FOUNDATION_EXPORT AFHTTPMethod const AFHTTPMethodPATCH;
/// HTTP DELETE 方法
FOUNDATION_EXPORT AFHTTPMethod const AFHTTPMethodDELETE;
/// HTTP CONNECT 方法
FOUNDATION_EXPORT AFHTTPMethod const AFHTTPMethodCONNECT;
/// HTTP OPTIONS 方法
FOUNDATION_EXPORT AFHTTPMethod const AFHTTPMethodOPTIONS;
/// HTTP TRACE 方法
FOUNDATION_EXPORT AFHTTPMethod const AFHTTPMethodTRACE;

NS_ASSUME_NONNULL_END