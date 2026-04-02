// ServerTrustManager.swift
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
import Security
#if SWIFT_PACKAGE
import AFNetworking
#endif

// MARK: - ServerTrustEvaluating

/// 服务器信任评估接口，对齐 Alamofire 的 `ServerTrustEvaluating`。
/// Swift throws 语义无法直接桥接 OC BOOL+NSError**，因此保留独立协议。
public protocol ServerTrustEvaluating: Sendable {
    func evaluate(_ serverTrust: SecTrust, forHost host: String) throws
}

// MARK: - Helper: bridge OC evaluator to Swift throws

private func evaluateWithObjC(_ evaluator: any AFServerTrustEvaluating,
                               serverTrust: SecTrust,
                               host: String) throws {
    try evaluator.evaluateServerTrust(serverTrust, forHost: host)
}

// MARK: - SecurityPolicyEvaluator

/// 将现有 `AFSecurityPolicy` 包装为 `ServerTrustEvaluating` 实现。
/// 桥接旧 API 与新抽象的适配器。底层委托 OC `AFSecurityPolicyEvaluator`。
public final class SecurityPolicyEvaluator: ServerTrustEvaluating, @unchecked Sendable {

    private let _evaluator: AFSecurityPolicyEvaluator

    /// 底层安全策略
    public var securityPolicy: AFSecurityPolicy { _evaluator.securityPolicy }

    public init(securityPolicy: AFSecurityPolicy) {
        self._evaluator = AFSecurityPolicyEvaluator(securityPolicy: securityPolicy)
    }

    public func evaluate(_ serverTrust: SecTrust, forHost host: String) throws {
        try evaluateWithObjC(_evaluator, serverTrust: serverTrust, host: host)
    }
}

// MARK: - Concrete Evaluators

/// 默认信任评估器：系统证书链验证（对齐 Alamofire `DefaultTrustEvaluator`）。
/// 底层委托 OC `AFDefaultTrustEvaluator`。
public struct DefaultTrustEvaluator: ServerTrustEvaluating, Sendable {
    private let _evaluator = AFDefaultTrustEvaluator()

    public init() {}

    public func evaluate(_ serverTrust: SecTrust, forHost host: String) throws {
        try evaluateWithObjC(_evaluator, serverTrust: serverTrust, host: host)
    }
}

/// 证书 Pinning 评估器（对齐 Alamofire `PinnedCertificatesTrustEvaluator`）。
/// 底层委托 OC `AFPinnedCertificatesTrustEvaluator`。
public struct PinnedCertificatesTrustEvaluator: ServerTrustEvaluating, @unchecked Sendable {
    private let _evaluator: AFPinnedCertificatesTrustEvaluator

    /// - Parameters:
    ///   - certificates: DER 编码的证书数据集合。传 `nil` 时自动从 main bundle 加载。
    ///   - validateCertificateChain: 是否验证完整证书链，默认 `true`。
    public init(certificates: Set<Data>? = nil, validateCertificateChain: Bool = true) {
        self._evaluator = AFPinnedCertificatesTrustEvaluator(
            certificates: certificates,
            validateCertificateChain: validateCertificateChain)
    }

    public func evaluate(_ serverTrust: SecTrust, forHost host: String) throws {
        try evaluateWithObjC(_evaluator, serverTrust: serverTrust, host: host)
    }
}

/// 公钥 Pinning 评估器（对齐 Alamofire `PublicKeysTrustEvaluator`）。
/// 底层委托 OC `AFPublicKeysTrustEvaluator`。
public struct PublicKeysTrustEvaluator: ServerTrustEvaluating, @unchecked Sendable {
    private let _evaluator: AFPublicKeysTrustEvaluator

    public init(certificates: Set<Data>? = nil) {
        self._evaluator = AFPublicKeysTrustEvaluator(certificates: certificates)
    }

    public func evaluate(_ serverTrust: SecTrust, forHost host: String) throws {
        try evaluateWithObjC(_evaluator, serverTrust: serverTrust, host: host)
    }
}

/// 禁用信任评估器：允许所有证书，**仅用于调试**（对齐 Alamofire `DisabledTrustEvaluator`）。
/// 底层委托 OC `AFDisabledTrustEvaluator`。
public struct DisabledTrustEvaluator: ServerTrustEvaluating, Sendable {
    private let _evaluator = AFDisabledTrustEvaluator()

    public init() {}

    public func evaluate(_ serverTrust: SecTrust, forHost host: String) throws {
        try evaluateWithObjC(_evaluator, serverTrust: serverTrust, host: host)
    }
}

/// 组合评估器：依次运行多个评估器，全部通过才算成功（对齐 Alamofire `CompositeTrustEvaluator`）。
public struct CompositeTrustEvaluator: ServerTrustEvaluating, @unchecked Sendable {
    private let evaluators: [any ServerTrustEvaluating]

    public init(evaluators: [any ServerTrustEvaluating]) {
        self.evaluators = evaluators
    }

    public func evaluate(_ serverTrust: SecTrust, forHost host: String) throws {
        for evaluator in evaluators {
            try evaluator.evaluate(serverTrust, forHost: host)
        }
    }
}

// MARK: - ServerTrustManager

/// 管理多个 host 的服务器信任评估策略，对齐 Alamofire 的 `ServerTrustManager`。
public final class ServerTrustManager: @unchecked Sendable {

    /// host -> evaluator 映射
    public let evaluators: [String: any ServerTrustEvaluating]

    /// 当请求的 host 不在映射中时，是否必须评估。默认 false（与现有 AFN 行为一致）。
    public var allUntrustedHostsMustBeEvaluated: Bool

    public init(evaluators: [String: any ServerTrustEvaluating],
                allUntrustedHostsMustBeEvaluated: Bool = false) {
        self.evaluators = evaluators
        self.allUntrustedHostsMustBeEvaluated = allUntrustedHostsMustBeEvaluated
    }

    /// 获取指定 host 的评估器
    public func evaluator(forHost host: String) -> (any ServerTrustEvaluating)? {
        evaluators[host]
    }

    /// 评估指定 host 的服务器信任
    public func evaluate(_ serverTrust: SecTrust, forHost host: String) throws {
        if let evaluator = evaluators[host] {
            try evaluator.evaluate(serverTrust, forHost: host)
        } else if allUntrustedHostsMustBeEvaluated {
            throw NSError(domain: AFServerTrustErrorDomain,
                          code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "No evaluator found for host: \(host)"])
        }
    }
}
