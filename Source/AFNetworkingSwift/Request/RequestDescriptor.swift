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
/// 底层实现委托给 OC 层 `AFRequestDescriptor`。
public class RequestDescriptor: @unchecked Sendable {

    /// 底层 OC 对象
    public let storage: AFRequestDescriptor

    /// 请求的 URL 字符串
    public var urlString: String { storage.urlString }

    /// HTTP 方法
    public var method: HTTPMethod { HTTPMethod(rawValue: storage.method) }

    /// 请求参数
    public var parameters: Any? { storage.parameters }

    /// 参数编码方式
    public var encoding: ParameterEncoding { ParameterEncoding(storage.encoding) }

    /// 请求头
    public var headers: HTTPHeaders? {
        storage.headers.map { HTTPHeaders(storage: $0) }
    }

    /// 请求超时时间，0 表示使用 manager 默认值
    public var timeoutInterval: TimeInterval {
        get { storage.timeoutInterval }
        set { storage.timeoutInterval = newValue }
    }

    /// 缓存策略
    public var cachePolicy: URLRequest.CachePolicy {
        get { storage.cachePolicy }
        set { storage.cachePolicy = newValue }
    }

    /// 单请求级别的请求序列化器，nil 表示使用 manager 默认值
    public var requestSerializer: (any AFURLRequestSerialization)? {
        get { storage.requestSerializer }
        set { storage.requestSerializer = newValue }
    }

    /// 单请求级别的响应序列化器，nil 表示使用 manager 默认值
    public var responseSerializer: (any AFURLResponseSerialization)? {
        get { storage.responseSerializer }
        set { storage.responseSerializer = newValue }
    }

    /// 单请求级别的拦截器（Swift-only，OC 层无对应）
    public var interceptor: (any RequestInterceptor)?

    /// 单请求级别的响应验证器数组（Swift-only wrapper，OC 层用 id<AFResponseValidator>）
    public var validators: [any ResponseValidating]?

    /// 用户自定义上下文信息
    public var userInfo: [String: Any]? {
        get { storage.userInfo as [String: Any]? }
        set { storage.userInfo = newValue }
    }

    /// 创建请求描述
    public init(urlString: String,
                method: HTTPMethod,
                parameters: Any? = nil,
                encoding: ParameterEncoding = .auto,
                headers: HTTPHeaders? = nil) {
        self.storage = AFRequestDescriptor(
            urlString: urlString,
            method: method.rawValue,
            parameters: parameters,
            encoding: encoding.objcEncoding,
            headers: headers?._storage)
    }

    /// 从 OC 对象创建
    internal init(storage: AFRequestDescriptor) {
        self.storage = storage
    }

    // MARK: - 便利构造

    /// GET 请求
    public static func get(_ urlString: String, parameters: Any? = nil, headers: HTTPHeaders? = nil) -> RequestDescriptor {
        RequestDescriptor(urlString: urlString, method: .get, parameters: parameters, headers: headers)
    }

    /// POST 请求
    public static func post(_ urlString: String, parameters: Any? = nil, headers: HTTPHeaders? = nil) -> RequestDescriptor {
        RequestDescriptor(urlString: urlString, method: .post, parameters: parameters, headers: headers)
    }

    /// PUT 请求
    public static func put(_ urlString: String, parameters: Any? = nil, headers: HTTPHeaders? = nil) -> RequestDescriptor {
        RequestDescriptor(urlString: urlString, method: .put, parameters: parameters, headers: headers)
    }

    /// DELETE 请求
    public static func delete(_ urlString: String, parameters: Any? = nil, headers: HTTPHeaders? = nil) -> RequestDescriptor {
        RequestDescriptor(urlString: urlString, method: .delete, parameters: parameters, headers: headers)
    }

    /// PATCH 请求
    public static func patch(_ urlString: String, parameters: Any? = nil, headers: HTTPHeaders? = nil) -> RequestDescriptor {
        RequestDescriptor(urlString: urlString, method: .patch, parameters: parameters, headers: headers)
    }
}

extension RequestDescriptor: CustomStringConvertible {
    public var description: String {
        "<RequestDescriptor: \(method.rawValue) \(urlString)>"
    }
}
