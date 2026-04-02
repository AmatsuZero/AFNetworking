// RetryPolicy.swift
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

// MARK: - RetryPolicy

/// 指数退避重试策略，对齐 Alamofire 的 `RetryPolicy`。
/// 底层委托给 OC 层 `AFRetryPolicy` 实现。
///
/// 重试延迟公式：`delay = pow(base, retryCount) * scale`
///
/// 用法：
/// ```swift
/// let session = Session(interceptor: RetryPolicy())
/// // 或自定义
/// let policy = RetryPolicy(retryLimit: 3, exponentialBackoffBase: 2, exponentialBackoffScale: 1.0)
/// ```
open class RetryPolicy: RequestInterceptor, @unchecked Sendable {

    /// 底层 OC 策略对象
    public let storage: AFRetryPolicy

    /// 最大重试次数
    public var retryLimit: UInt { UInt(storage.retryLimit) }

    /// 指数退避底数
    public var exponentialBackoffBase: Double { storage.exponentialBackoffBase }

    /// 指数退避缩放因子
    public var exponentialBackoffScale: Double { storage.exponentialBackoffScale }

    /// 可重试的 HTTP 方法集合
    public var retryableHTTPMethods: Set<String> { storage.retryableHTTPMethods as! Set<String> }

    /// 可重试的 HTTP 状态码
    public var retryableHTTPStatusCodes: IndexSet { storage.retryableHTTPStatusCodes as IndexSet }

    /// 可重试的 URL 错误码
    public var retryableURLErrorCodes: Set<Int> {
        Set((storage.retryableURLErrorCodes as! Set<NSNumber>).map { $0.intValue })
    }

    /// 使用默认配置创建
    public init() {
        self.storage = AFRetryPolicy.default()
    }

    /// 完整初始化
    public init(retryLimit: UInt = 2,
                exponentialBackoffBase: Double = 2.0,
                exponentialBackoffScale: Double = 0.5,
                retryableHTTPMethods: Set<String> = ["DELETE", "GET", "HEAD", "OPTIONS", "PUT", "TRACE"],
                retryableHTTPStatusCodes: Set<Int> = [408, 500, 502, 503, 504],
                retryableURLErrorCodes: Set<Int> = [
                    NSURLErrorTimedOut,
                    NSURLErrorCannotFindHost,
                    NSURLErrorCannotConnectToHost,
                    NSURLErrorDNSLookupFailed,
                    NSURLErrorNetworkConnectionLost,
                    NSURLErrorNotConnectedToInternet,
                    NSURLErrorInternationalRoamingOff,
                    NSURLErrorSecureConnectionFailed
                ]) {
        let statusIndexSet = NSMutableIndexSet()
        for code in retryableHTTPStatusCodes { statusIndexSet.add(code) }

        self.storage = AFRetryPolicy(
            retryLimit: UInt(retryLimit),
            exponentialBackoffBase: exponentialBackoffBase,
            exponentialBackoffScale: exponentialBackoffScale,
            retryableHTTPMethods: retryableHTTPMethods as NSSet as! Set<String>,
            retryableHTTPStatusCodes: statusIndexSet as IndexSet,
            retryableURLErrorCodes: Set(retryableURLErrorCodes.map { NSNumber(value: $0) })
        )
    }

    /// 从 OC 对象创建
    public init(storage: AFRetryPolicy) {
        self.storage = storage
    }

    // MARK: - RequestAdapter（不做任何适配）

    public func adaptRequest(_ request: URLRequest, completion: @escaping @Sendable (URLRequest?, (any Error)?) -> Void) {
        completion(request, nil)
    }

    // MARK: - RequestRetrier（委托给 OC 层）

    public func shouldRetry(_ request: URLRequest, withError error: any Error, retryCount: UInt, completion: @escaping @Sendable (RetryResult, (any Error)?) -> Void) {
        // 使用 OC AFRetryPolicy 的判断逻辑 + 延迟计算
        let shouldRetry = storage.shouldRetry(request, response: nil, withError: error)
        if retryCount < storage.retryLimit && shouldRetry {
            let delay = storage.retryDelay(forRetryCount: retryCount)
            completion(.retryWithDelay(delay), nil)
        } else {
            completion(.doNotRetry, nil)
        }
    }
}

// MARK: - ConnectionLostRetryPolicy

/// 连接丢失重试策略，对齐 Alamofire 的 `ConnectionLostRetryPolicy`。
/// 仅在网络连接丢失（`NSURLErrorNetworkConnectionLost`）时重试。
open class ConnectionLostRetryPolicy: RetryPolicy, @unchecked Sendable {

    /// 使用默认配置创建
    public override init() {
        super.init(storage: AFConnectionLostRetryPolicy.default())
    }

    /// 自定义初始化
    public init(retryLimit: UInt = 2,
                exponentialBackoffBase: Double = 2.0,
                exponentialBackoffScale: Double = 0.5) {
        let ocPolicy = AFConnectionLostRetryPolicy(
            retryLimit: retryLimit,
            exponentialBackoffBase: exponentialBackoffBase,
            exponentialBackoffScale: exponentialBackoffScale
        )
        super.init(storage: ocPolicy)
    }
}
