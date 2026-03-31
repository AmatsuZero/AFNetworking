// AFSwiftSupport.h
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

#ifndef _AFSWIFTSUPPORT_
#define _AFSWIFTSUPPORT_

// 请求描述与配置
#import "AFHTTPMethod.h"
#import "AFHTTPHeaders.h"
#import "AFRequestDescriptor.h"
#import "AFRequestContext.h"

// 拦截器与重试
#import "AFRequestInterceptor.h"

// 响应结果
#import "AFDataResponse.h"
#import "AFDownloadResponse.h"

// 验证器
#import "AFResponseValidator.h"

// 事件监控
#import "AFEventMonitor.h"

// 多 Host 信任管理
#import "AFServerTrustManager.h"

#endif /* _AFSWIFTSUPPORT_ */