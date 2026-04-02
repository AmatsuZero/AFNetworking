// RetryResult.swift
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
@preconcurrency import AFNetworking

/// 重试决策结果，对齐 Alamofire 的 `RetryResult`。
/// 底层委托给 OC `AFRetryResult`。
public enum RetryResult: Sendable {
    /// 执行重试
    case retry
    /// 延迟重试
    case retryWithDelay(TimeInterval)
    /// 不重试，使用原始错误
    case doNotRetry
    /// 不重试，使用指定错误
    case doNotRetryWithError(any Error)

    /// 转为 OC AFRetryResult
    public var objcResult: AFRetryResult {
        switch self {
        case .retry: return .retry()
        case .retryWithDelay(let delay): return .retry(withDelay: delay)
        case .doNotRetry: return .doNotRetry()
        case .doNotRetryWithError(let error): return AFRetryResult.doNotRetryWithError(error as NSError)
        }
    }

    /// 从 OC AFRetryResult 创建
    public init(_ objcResult: AFRetryResult) {
        switch objcResult.type {
        case .retry: self = .retry
        case .retryWithDelay: self = .retryWithDelay(objcResult.delay)
        case .doNotRetry: self = .doNotRetry
        case .doNotRetryWithError: self = .doNotRetryWithError(objcResult.error ?? NSError(domain: "AFNetworking", code: -1))
        @unknown default: self = .doNotRetry
        }
    }
}
