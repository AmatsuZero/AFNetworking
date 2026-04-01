// ResponseValidator.swift
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

// MARK: - Error Constants

/// 响应验证错误域
public let ResponseValidationErrorDomain = "com.alamofire.error.validation"

/// 响应验证错误码
public enum ResponseValidationError: Int {
    /// 状态码不在可接受范围内
    case unacceptableStatusCode = -1000
    /// Content-Type 不在可接受范围内
    case unacceptableContentType = -1001
    /// 自定义验证失败
    case customValidationFailed = -1002
}

/// 验证错误 userInfo key：实际状态码
public let ResponseValidationErrorStatusCodeKey = "com.alamofire.validation.statusCode"
/// 验证错误 userInfo key：可接受状态码集合
public let ResponseValidationErrorAcceptableStatusCodesKey = "com.alamofire.validation.acceptableStatusCodes"
/// 验证错误 userInfo key：实际 Content-Type
public let ResponseValidationErrorContentTypeKey = "com.alamofire.validation.contentType"
/// 验证错误 userInfo key：可接受 Content-Type 集合
public let ResponseValidationErrorAcceptableContentTypesKey = "com.alamofire.validation.acceptableContentTypes"

// MARK: - ResponseValidating

/// 响应验证器协议，对齐 Alamofire 的验证链式设计。
public protocol ResponseValidating: Sendable {
    /// 验证响应
    /// - Parameters:
    ///   - request: 原始请求
    ///   - response: HTTP 响应
    ///   - data: 响应数据
    /// - Returns: 验证失败时返回错误，成功返回 nil
    func validate(_ request: URLRequest?, response: HTTPURLResponse, data: Data?) -> NSError?
}

// MARK: - StatusCodeValidator

/// 验证响应状态码是否在可接受范围内。默认可接受范围为 200-299。
public struct StatusCodeValidator: ResponseValidating {

    /// 可接受的状态码集合
    public let acceptableStatusCodes: IndexSet

    /// 使用可接受状态码范围创建
    public init(acceptableStatusCodes: IndexSet) {
        self.acceptableStatusCodes = acceptableStatusCodes
    }

    /// 默认验证器（200-299）
    public static func `default`() -> StatusCodeValidator {
        StatusCodeValidator(acceptableStatusCodes: IndexSet(integersIn: 200..<300))
    }

    public func validate(_ request: URLRequest?, response: HTTPURLResponse, data: Data?) -> NSError? {
        if acceptableStatusCodes.contains(response.statusCode) {
            return nil
        }

        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: "Response status code was unacceptable: \(response.statusCode).",
            ResponseValidationErrorStatusCodeKey: response.statusCode,
            ResponseValidationErrorAcceptableStatusCodesKey: acceptableStatusCodes,
        ]
        return NSError(domain: ResponseValidationErrorDomain,
                       code: ResponseValidationError.unacceptableStatusCode.rawValue,
                       userInfo: userInfo)
    }
}

// MARK: - ContentTypeValidator

/// 验证响应 Content-Type 是否在可接受范围内。
public struct ContentTypeValidator: ResponseValidating {

    /// 可接受的 Content-Type 集合
    public let acceptableContentTypes: Set<String>

    /// 使用可接受 Content-Type 集合创建
    public init(acceptableContentTypes: Set<String>) {
        self.acceptableContentTypes = acceptableContentTypes
    }

    public func validate(_ request: URLRequest?, response: HTTPURLResponse, data: Data?) -> NSError? {
        guard let contentType = response.value(forHTTPHeaderField: "Content-Type") else {
            // 没有 Content-Type 头时，如果有数据则视为不可接受
            if let data = data, !data.isEmpty {
                return makeError(actualContentType: "nil")
            }
            return nil
        }

        // 提取 MIME type（去掉参数部分，如 charset）
        let mimeType = contentType.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespaces) ?? contentType

        for acceptable in acceptableContentTypes {
            if acceptable == mimeType {
                return nil
            }
            // 支持通配符匹配，如 "text/*"
            if acceptable.hasSuffix("/*") {
                let prefix = String(acceptable.dropLast(2))
                if mimeType.hasPrefix(prefix) {
                    return nil
                }
            }
            if acceptable == "*/*" {
                return nil
            }
        }

        return makeError(actualContentType: mimeType)
    }

    private func makeError(actualContentType: String) -> NSError {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: "Response Content-Type \"\(actualContentType)\" does not match any acceptable Content-Type: \(acceptableContentTypes).",
            ResponseValidationErrorContentTypeKey: actualContentType,
            ResponseValidationErrorAcceptableContentTypesKey: acceptableContentTypes,
        ]
        return NSError(domain: ResponseValidationErrorDomain,
                       code: ResponseValidationError.unacceptableContentType.rawValue,
                       userInfo: userInfo)
    }
}

// MARK: - BlockResponseValidator

/// 使用 block 实现自定义验证逻辑。
public struct BlockResponseValidator: ResponseValidating {
    public typealias ValidationBlock = @Sendable (URLRequest?, HTTPURLResponse, Data?) -> NSError?

    private let block: ValidationBlock

    /// 使用 block 创建验证器
    public init(block: @escaping ValidationBlock) {
        self.block = block
    }

    public func validate(_ request: URLRequest?, response: HTTPURLResponse, data: Data?) -> NSError? {
        block(request, response, data)
    }
}
