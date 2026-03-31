// AFError.swift
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

/// AFNetworkingSwift 统一错误类型，对齐 Alamofire 的 `AFError`。
public enum AFError: Error {
    /// 请求创建失败
    case createURLRequestFailed(error: Error)
    /// 请求适配失败
    case requestAdaptationFailed(error: Error)
    /// 响应验证失败
    case responseValidationFailed(reason: String)
    /// 响应序列化失败
    case responseSerializationFailed(reason: String)
    /// 服务器信任评估失败
    case serverTrustEvaluationFailed(reason: String)
    /// 请求重试失败（已达最大重试次数）
    case requestRetryFailed(retryError: Error, originalError: Error)
    /// 请求被取消
    case explicitlyCancelled
    /// 会话已释放
    case sessionDeinitialized
    /// URL 无效
    case invalidURL(url: String)
}

extension AFError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .createURLRequestFailed(let error):
            return "URL request creation failed with error: \(error.localizedDescription)"
        case .requestAdaptationFailed(let error):
            return "Request adaptation failed with error: \(error.localizedDescription)"
        case .responseValidationFailed(let reason):
            return "Response validation failed: \(reason)"
        case .responseSerializationFailed(let reason):
            return "Response serialization failed: \(reason)"
        case .serverTrustEvaluationFailed(let reason):
            return "Server trust evaluation failed: \(reason)"
        case .requestRetryFailed(let retryError, let originalError):
            return "Request retry failed with error: \(retryError.localizedDescription), original: \(originalError.localizedDescription)"
        case .explicitlyCancelled:
            return "Request explicitly cancelled"
        case .sessionDeinitialized:
            return "Session was deinitialized"
        case .invalidURL(let url):
            return "URL is not valid: \(url)"
        }
    }
}