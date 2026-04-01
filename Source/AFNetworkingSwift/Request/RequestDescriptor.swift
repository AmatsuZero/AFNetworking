// RequestDescriptor.swift
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

import Foundation
#if SWIFT_PACKAGE
import AFNetworking
#endif

/// 描述单个请求的完整配置，对齐 Alamofire 中 `Session.request(...)` 方法接受的参数集合。
public class RequestDescriptor: @unchecked Sendable {

    /// 请求的 URL 字符串
    public let urlString: String

    /// HTTP 方法
    public let method: HTTPMethod

    /// 请求参数
    public let parameters: Any?

    /// 参数编码方式
    public let encoding: ParameterEncoding

    /// 请求头
    public let headers: HTTPHeaders?

    /// 请求超时时间，0 表示使用 manager 默认值
    public var timeoutInterval: TimeInterval = 0

    /// 缓存策略
    public var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy

    /// 单请求级别的请求序列化器，nil 表示使用 manager 默认值
    public var requestSerializer: (any AFURLRequestSerialization)?

    /// 单请求级别的响应序列化器，nil 表示使用 manager 默认值
    public var responseSerializer: (any AFURLResponseSerialization)?

    /// 单请求级别的拦截器
    public var interceptor: (any RequestIntercepting)?

    /// 单请求级别的响应验证器数组
    public var validators: [any ResponseValidating]?

    /// 用户自定义上下文信息
    public var userInfo: [String: Any]?

    /// 创建请求描述
    public init(urlString: String,
                method: HTTPMethod,
                parameters: Any? = nil,
                encoding: ParameterEncoding = .auto,
                headers: HTTPHeaders? = nil) {
        self.urlString = urlString
        self.method = method
        self.parameters = parameters
        self.encoding = encoding
        self.headers = headers
    }

    // MARK: - 便利构造

    /// GET 请求
    public static func GET(_ urlString: String, parameters: Any? = nil, headers: HTTPHeaders? = nil) -> RequestDescriptor {
        RequestDescriptor(urlString: urlString, method: .GET, parameters: parameters, headers: headers)
    }

    /// POST 请求
    public static func POST(_ urlString: String, parameters: Any? = nil, headers: HTTPHeaders? = nil) -> RequestDescriptor {
        RequestDescriptor(urlString: urlString, method: .POST, parameters: parameters, headers: headers)
    }

    /// PUT 请求
    public static func PUT(_ urlString: String, parameters: Any? = nil, headers: HTTPHeaders? = nil) -> RequestDescriptor {
        RequestDescriptor(urlString: urlString, method: .PUT, parameters: parameters, headers: headers)
    }

    /// DELETE 请求
    public static func DELETE(_ urlString: String, parameters: Any? = nil, headers: HTTPHeaders? = nil) -> RequestDescriptor {
        RequestDescriptor(urlString: urlString, method: .DELETE, parameters: parameters, headers: headers)
    }

    /// PATCH 请求
    public static func PATCH(_ urlString: String, parameters: Any? = nil, headers: HTTPHeaders? = nil) -> RequestDescriptor {
        RequestDescriptor(urlString: urlString, method: .PATCH, parameters: parameters, headers: headers)
    }
}

extension RequestDescriptor: CustomStringConvertible {
    public var description: String {
        "<RequestDescriptor: \(method.rawValue) \(urlString)>"
    }
}
