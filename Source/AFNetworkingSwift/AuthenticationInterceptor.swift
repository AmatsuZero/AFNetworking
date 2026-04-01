// AuthenticationInterceptor.swift
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
import AFSwiftSupport
#endif

// MARK: - 认证凭据协议

/// 认证凭据协议，对齐 Alamofire 的 `AuthenticationCredential`。
public protocol AuthenticationCredential {
    /// 凭据是否需要刷新
    var requiresRefresh: Bool { get }
}

// MARK: - 认证器协议

/// 认证器协议，对齐 Alamofire 的 `Authenticator`。
public protocol Authenticator {
    associatedtype Credential: AuthenticationCredential

    /// 将凭据应用到请求
    func apply(_ credential: Credential, to urlRequest: inout URLRequest)

    /// 刷新凭据
    func refresh(_ credential: Credential, for session: Session, completion: @escaping (Result<Credential, Error>) -> Void)

    /// 判断请求是否因认证失败
    func didRequest(_ urlRequest: URLRequest, with response: HTTPURLResponse, failDueToAuthenticationError error: Error) -> Bool

    /// 判断请求是否需要使用凭据认证
    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: Credential) -> Bool
}

// MARK: - 认证拦截器

/// 认证拦截器，对齐 Alamofire 的 `AuthenticationInterceptor`。
/// 自动注入凭据、检测 401 并刷新 token 后重试。
public final class AuthenticationInterceptor<AuthenticatorType: Authenticator>: NSObject, RequestIntercepting {

    /// 关联的 Session（用于 credential 刷新）
    public weak var session: Session?

    /// 认证器
    public let authenticator: AuthenticatorType

    /// 当前凭据
    public private(set) var credential: AuthenticatorType.Credential?

    /// 最大刷新次数
    public let maxRefreshCount: Int

    /// 当前刷新次数
    private var refreshCount = 0

    /// 是否正在刷新
    private var isRefreshing = false

    /// 等待刷新完成的请求队列
    private var pendingAdaptations: [(URLRequest, (URLRequest?, Error?) -> Void)] = []
    private var pendingRetries: [(URLRequest, any Error, UInt, @Sendable (RetryResult, (any Error)?) -> Void)] = []

    private let lock = NSLock()

    /// 创建认证拦截器
    /// - Parameters:
    ///   - authenticator: 认证器
    ///   - credential: 初始凭据
    ///   - maxRefreshCount: 最大刷新次数，默认 2
    public init(authenticator: AuthenticatorType,
                credential: AuthenticatorType.Credential? = nil,
                maxRefreshCount: Int = 2) {
        self.authenticator = authenticator
        self.credential = credential
        self.maxRefreshCount = maxRefreshCount
    }

    // MARK: - RequestAdapting

    public func adaptRequest(_ request: URLRequest, completion: @escaping (URLRequest?, (any Error)?) -> Void) {
        lock.lock()
        guard let credential = credential else {
            lock.unlock()
            completion(request, nil)
            return
        }

        if credential.requiresRefresh {
            pendingAdaptations.append((request, completion))
            lock.unlock()
            refreshCredentialIfNeeded()
            return
        }

        lock.unlock()
        var mutableRequest = request
        authenticator.apply(credential, to: &mutableRequest)
        completion(mutableRequest, nil)
    }

    // MARK: - RequestRetrying

    public func shouldRetry(_ request: URLRequest, withError error: any Error, retryCount: UInt, completion: @escaping @Sendable (RetryResult, (any Error)?) -> Void) {
        // 此处简化：如果不是 HTTP 响应错误，不重试
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain || nsError.domain == ResponseValidationErrorDomain else {
            completion(.doNotRetry, nil)
            return
        }

        lock.lock()
        guard credential != nil else {
            lock.unlock()
            completion(.doNotRetry, nil)
            return
        }

        if refreshCount >= maxRefreshCount {
            lock.unlock()
            completion(.doNotRetry, nil)
            return
        }

        pendingRetries.append((request, error, retryCount, completion))
        lock.unlock()
        refreshCredentialIfNeeded()
    }

    // MARK: - 刷新

    private func refreshCredentialIfNeeded() {
        lock.lock()
        guard !isRefreshing else {
            lock.unlock()
            return
        }
        guard let credential = credential else {
            lock.unlock()
            return
        }
        isRefreshing = true
        refreshCount += 1
        lock.unlock()

        authenticator.refresh(credential, for: session ?? Session.default) { [weak self] result in
            guard let self = self else { return }
            self.lock.lock()
            self.isRefreshing = false

            switch result {
            case .success(let newCredential):
                self.credential = newCredential

                // 处理等待中的适配请求
                let adaptations = self.pendingAdaptations
                self.pendingAdaptations = []

                // 处理等待中的重试请求
                let retries = self.pendingRetries
                self.pendingRetries = []

                self.lock.unlock()

                for (request, completion) in adaptations {
                    var mutableRequest = request
                    self.authenticator.apply(newCredential, to: &mutableRequest)
                    completion(mutableRequest, nil)
                }

                for (_, _, _, completion) in retries {
                    completion(.retry, nil)
                }

            case .failure(let error):
                let adaptations = self.pendingAdaptations
                self.pendingAdaptations = []
                let retries = self.pendingRetries
                self.pendingRetries = []
                self.lock.unlock()

                for (_, completion) in adaptations {
                    completion(nil, error)
                }
                for (_, _, _, completion) in retries {
                    completion(.doNotRetryWithError, error as NSError)
                }
            }
        }
    }
}

// MARK: - 重试策略

/// 退避重试策略，对齐 Alamofire 的 `RetryPolicy`。
public final class RetryPolicy: NSObject, RequestRetrying {

    /// 最大重试次数
    public let retryLimit: UInt

    /// 指数退避基数（秒）
    public let exponentialBackoffBase: Double

    /// 指数退避倍数
    public let exponentialBackoffScale: Double

    /// 可重试的 HTTP 方法
    public let retryableHTTPMethods: Set<String>

    /// 可重试的 URL 错误码
    public let retryableURLErrorCodes: Set<Int>

    /// 创建重试策略
    /// - Parameters:
    ///   - retryLimit: 最大重试次数，默认 2
    ///   - exponentialBackoffBase: 退避基数，默认 2
    ///   - exponentialBackoffScale: 退避倍数，默认 0.5
    ///   - retryableHTTPMethods: 可重试的 HTTP 方法
    ///   - retryableURLErrorCodes: 可重试的 URL 错误码
    public init(retryLimit: UInt = 2,
                exponentialBackoffBase: Double = 2,
                exponentialBackoffScale: Double = 0.5,
                retryableHTTPMethods: Set<String> = ["DELETE", "GET", "HEAD", "OPTIONS", "PUT", "TRACE"],
                retryableURLErrorCodes: Set<Int> = [
                    NSURLErrorTimedOut,
                    NSURLErrorCannotFindHost,
                    NSURLErrorCannotConnectToHost,
                    NSURLErrorNetworkConnectionLost,
                    NSURLErrorDNSLookupFailed,
                    NSURLErrorNotConnectedToInternet,
                    NSURLErrorInternationalRoamingOff,
                    NSURLErrorSecureConnectionFailed,
                    NSURLErrorCannotLoadFromNetwork
                ]) {
        self.retryLimit = retryLimit
        self.exponentialBackoffBase = exponentialBackoffBase
        self.exponentialBackoffScale = exponentialBackoffScale
        self.retryableHTTPMethods = retryableHTTPMethods
        self.retryableURLErrorCodes = retryableURLErrorCodes
    }

    public func shouldRetry(_ request: URLRequest, withError error: any Error, retryCount: UInt, completion: @escaping @Sendable (RetryResult, (any Error)?) -> Void) {
        guard retryCount < retryLimit else {
            completion(.doNotRetry, nil)
            return
        }

        let nsError = error as NSError
        guard retryableURLErrorCodes.contains(nsError.code) else {
            completion(.doNotRetry, nil)
            return
        }

        if let method = request.httpMethod, !retryableHTTPMethods.contains(method.uppercased()) {
            completion(.doNotRetry, nil)
            return
        }

        let delay = pow(exponentialBackoffBase, Double(retryCount)) * exponentialBackoffScale
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            completion(.retry, nil)
        }
    }
}