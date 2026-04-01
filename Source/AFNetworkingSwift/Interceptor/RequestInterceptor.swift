// RequestInterceptor.swift
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

// MARK: - RequestAdapting

/// 请求适配器协议，在请求发送前修改 URLRequest。
/// 对齐 Alamofire 的 `RequestAdapter`。
public protocol RequestAdapting: Sendable {
    /// 适配请求
    /// - Parameters:
    ///   - request: 原始请求
    ///   - completion: 完成回调，传入修改后的请求或错误
    func adaptRequest(_ request: URLRequest, completion: @escaping @Sendable (URLRequest?, (any Error)?) -> Void)
}

// MARK: - RequestRetrying

/// 请求重试器协议，在请求失败后决定是否重试。
/// 对齐 Alamofire 的 `RequestRetrier`。
public protocol RequestRetrying: Sendable {
    /// 决定是否重试
    /// - Parameters:
    ///   - request: 失败的请求
    ///   - error: 失败错误
    ///   - retryCount: 当前已重试次数
    ///   - completion: 完成回调，传入重试结果和可选的替代错误
    func shouldRetry(_ request: URLRequest, withError error: any Error, retryCount: UInt, completion: @escaping @Sendable (RetryResult, (any Error)?) -> Void)
}

// MARK: - RequestIntercepting

/// 组合适配器和重试器的协议，对齐 Alamofire 的 `RequestInterceptor`。
public typealias RequestIntercepting = RequestAdapting & RequestRetrying

// MARK: - Interceptor（默认组合实现）

/// `Interceptor` 是 `RequestIntercepting` 的默认组合实现。
/// 可以分别设置 adapter 和 retrier，也可以同时设置。
public final class Interceptor: RequestIntercepting, @unchecked Sendable {

    /// 请求适配器
    public let adapter: (any RequestAdapting)?

    /// 请求重试器
    public let retrier: (any RequestRetrying)?

    /// 使用适配器和重试器创建拦截器
    public init(adapter: (any RequestAdapting)? = nil, retrier: (any RequestRetrying)? = nil) {
        self.adapter = adapter
        self.retrier = retrier
    }

    public func adaptRequest(_ request: URLRequest, completion: @escaping @Sendable (URLRequest?, (any Error)?) -> Void) {
        if let adapter = adapter {
            adapter.adaptRequest(request, completion: completion)
        } else {
            completion(request, nil)
        }
    }

    public func shouldRetry(_ request: URLRequest, withError error: any Error, retryCount: UInt, completion: @escaping @Sendable (RetryResult, (any Error)?) -> Void) {
        if let retrier = retrier {
            retrier.shouldRetry(request, withError: error, retryCount: retryCount, completion: completion)
        } else {
            completion(.doNotRetry, nil)
        }
    }
}

// MARK: - BlockRequestAdapter

/// 使用 block 实现请求适配。
public struct BlockRequestAdapter: RequestAdapting {
    public typealias Handler = @Sendable (URLRequest, @escaping @Sendable (URLRequest?, (any Error)?) -> Void) -> Void

    private let handler: Handler

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func adaptRequest(_ request: URLRequest, completion: @escaping @Sendable (URLRequest?, (any Error)?) -> Void) {
        handler(request, completion)
    }
}

// MARK: - BlockRequestRetrier

/// 使用 block 实现请求重试决策。
public struct BlockRequestRetrier: RequestRetrying {
    public typealias Handler = @Sendable (URLRequest, any Error, UInt, @escaping @Sendable (RetryResult, (any Error)?) -> Void) -> Void

    private let handler: Handler

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func shouldRetry(_ request: URLRequest, withError error: any Error, retryCount: UInt, completion: @escaping @Sendable (RetryResult, (any Error)?) -> Void) {
        handler(request, error, retryCount, completion)
    }
}

// MARK: - async-first 协议扩展

/// async-first 适配器扩展：提供 async throws 版本，默认桥接 callback API。
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension RequestAdapting {
    /// async 版本的适配请求
    func adapt(_ request: URLRequest) async throws -> URLRequest {
        try await withCheckedThrowingContinuation { continuation in
            adaptRequest(request) { adaptedRequest, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let adaptedRequest = adaptedRequest {
                    continuation.resume(returning: adaptedRequest)
                } else {
                    continuation.resume(returning: request)
                }
            }
        }
    }
}

/// async-first 重试器扩展：提供 async 版本，默认桥接 callback API。
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension RequestRetrying {
    /// async 版本的重试决策
    func retry(_ request: URLRequest, withError error: any Error, retryCount: UInt) async -> (RetryResult, (any Error)?) {
        await withCheckedContinuation { continuation in
            shouldRetry(request, withError: error, retryCount: retryCount) { result, retryError in
                continuation.resume(returning: (result, retryError))
            }
        }
    }
}
