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
#endif

// MARK: - 认证凭据协议

/// 认证凭据协议
public protocol AuthenticationCredential: Sendable {
    /// 凭据是否需要刷新
    var requiresRefresh: Bool { get }
}

// MARK: - 认证器协议

/// 认证器协议
public protocol Authenticator: Sendable {
    associatedtype Credential: AuthenticationCredential

    /// 将凭据应用到请求
    func apply(_ credential: Credential, to urlRequest: inout URLRequest)

    /// 刷新凭据
    func refresh(_ credential: Credential, for session: Session, completion: @escaping @Sendable (Result<Credential, Error>) -> Void)

    /// 判断请求是否因认证失败
    func didRequest(_ urlRequest: URLRequest, with response: HTTPURLResponse, failDueToAuthenticationError error: Error) -> Bool

    /// 判断请求是否需要使用凭据认证
    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: Credential) -> Bool
}

// MARK: - AuthState Actor

/// 内部 Actor 封装认证拦截器的可变状态，替代 NSLock。
actor AuthState<A: Authenticator> {
    var credential: A.Credential?
    var isRefreshing = false
    var refreshCount = 0
    var pendingAdaptations: [(URLRequest, @Sendable (URLRequest?, (any Error)?) -> Void)] = []
    var pendingRetries: [(URLRequest, any Error, UInt, @Sendable (RetryResult, (any Error)?) -> Void)] = []

    init(credential: A.Credential?) {
        self.credential = credential
    }

    func getCredential() -> A.Credential? { credential }

    func setCredential(_ newCredential: A.Credential) {
        credential = newCredential
    }

    func beginRefresh() -> Bool {
        guard !isRefreshing else { return false }
        isRefreshing = true
        refreshCount += 1
        return true
    }

    func endRefresh() {
        isRefreshing = false
    }

    func canRetry(maxRefreshCount: Int) -> Bool {
        refreshCount < maxRefreshCount
    }

    func enqueuePendingAdaptation(_ item: (URLRequest, @Sendable (URLRequest?, (any Error)?) -> Void)) {
        pendingAdaptations.append(item)
    }

    func enqueuePendingRetry(_ item: (URLRequest, any Error, UInt, @Sendable (RetryResult, (any Error)?) -> Void)) {
        pendingRetries.append(item)
    }

    func drainPendingAdaptations() -> [(URLRequest, @Sendable (URLRequest?, (any Error)?) -> Void)] {
        let result = pendingAdaptations
        pendingAdaptations = []
        return result
    }

    func drainPendingRetries() -> [(URLRequest, any Error, UInt, @Sendable (RetryResult, (any Error)?) -> Void)] {
        let result = pendingRetries
        pendingRetries = []
        return result
    }
}

// MARK: - 认证拦截器

/// 认证拦截器，对齐 Alamofire 的 `AuthenticationInterceptor`。
/// 自动注入凭据、检测 401 并刷新 token 后重试。
public final class AuthenticationInterceptor<AuthenticatorType: Authenticator>: RequestInterceptor, @unchecked Sendable {

    /// 关联的 Session（用于 credential 刷新）
    public weak var session: Session?

    /// 认证器
    public let authenticator: AuthenticatorType

    /// 当前凭据（同步访问，内部由 actor 保护）
    public var credential: AuthenticatorType.Credential? {
        // 提供同步只读访问（best-effort snapshot）
        _credentialSnapshot
    }
    private var _credentialSnapshot: AuthenticatorType.Credential?

    /// 最大刷新次数
    public let maxRefreshCount: Int

    /// 内部 Actor 封装可变状态
    private let state: AuthState<AuthenticatorType>

    /// 创建认证拦截器
    /// - Parameters:
    ///   - authenticator: 认证器
    ///   - credential: 初始凭据
    ///   - maxRefreshCount: 最大刷新次数，默认 2
    public init(authenticator: AuthenticatorType,
                credential: AuthenticatorType.Credential? = nil,
                maxRefreshCount: Int = 2) {
        self.authenticator = authenticator
        self._credentialSnapshot = credential
        self.maxRefreshCount = maxRefreshCount
        self.state = AuthState<AuthenticatorType>(credential: credential)
    }

    // MARK: - RequestAdapter

    public func adaptRequest(_ request: URLRequest, completion: @escaping @Sendable (URLRequest?, (any Error)?) -> Void) {
        Task {
            guard let credential = await state.getCredential() else {
                completion(request, nil)
                return
            }

            if credential.requiresRefresh {
                await state.enqueuePendingAdaptation((request, completion))
                await refreshCredentialIfNeeded()
                return
            }

            var mutableRequest = request
            authenticator.apply(credential, to: &mutableRequest)
            completion(mutableRequest, nil)
        }
    }

    // MARK: - RequestRetrier

    public func shouldRetry(_ request: URLRequest, withError error: any Error, retryCount: UInt, completion: @escaping @Sendable (RetryResult, (any Error)?) -> Void) {
        // 此处简化：如果不是 HTTP 响应错误，不重试
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain || nsError.domain == ResponseValidationErrorDomain else {
            completion(.doNotRetry, nil)
            return
        }

        Task {
            guard await state.getCredential() != nil else {
                completion(.doNotRetry, nil)
                return
            }

            guard await state.canRetry(maxRefreshCount: maxRefreshCount) else {
                completion(.doNotRetry, nil)
                return
            }

            await state.enqueuePendingRetry((request, error, retryCount, completion))
            await refreshCredentialIfNeeded()
        }
    }

    // MARK: - 刷新

    private func refreshCredentialIfNeeded() async {
        guard await state.beginRefresh() else { return }

        guard let credential = await state.getCredential() else {
            await state.endRefresh()
            return
        }

        authenticator.refresh(credential, for: session ?? Session.default) { [weak self] result in
            guard let self = self else { return }
            let result = result // rebind for Sendable capture
            Task { @Sendable in
                await self.state.endRefresh()

                switch result {
                case .success(let newCredential):
                    await self.state.setCredential(newCredential)
                    self._credentialSnapshot = newCredential

                    let adaptations = await self.state.drainPendingAdaptations()
                    let retries = await self.state.drainPendingRetries()

                    for (request, completion) in adaptations {
                        var mutableRequest = request
                        self.authenticator.apply(newCredential, to: &mutableRequest)
                        completion(mutableRequest, nil)
                    }

                    for (_, _, _, completion) in retries {
                        completion(.retry, nil)
                    }

                case .failure(let error):
                    let adaptations = await self.state.drainPendingAdaptations()
                    let retries = await self.state.drainPendingRetries()

                    for (_, completion) in adaptations {
                        completion(nil, error)
                    }
                    for (_, _, _, completion) in retries {
                        completion(.doNotRetryWithError(error), error as NSError)
                    }
                }
            }
        }
    }
}
