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
import AFNetworking

// MARK: - ResponseValidating (Swift protocol bridging AFResponseValidator)

/// 响应验证器协议，对齐 Alamofire 的验证链式设计。
/// 底层实现委托给 OC 层 `AFResponseValidator` 协议。
public protocol ResponseValidating: Sendable {
    func validate(_ request: URLRequest?, response: HTTPURLResponse, data: Data?) -> NSError?
}

// MARK: - OC 类型的 Swift 包装，实现 ResponseValidating

/// 通用包装器：将任意 AFResponseValidator OC 对象包装为 Swift ResponseValidating
struct ObjCResponseValidatorWrapper: ResponseValidating, @unchecked Sendable {
    let validator: any AFResponseValidator

    func validate(_ request: URLRequest?, response: HTTPURLResponse, data: Data?) -> NSError? {
        validator.validate(request, response: response, data: data) as NSError?
    }
}

// MARK: - StatusCodeValidator

/// 验证响应状态码是否在可接受范围内。底层委托给 OC `AFStatusCodeValidator`。
public struct StatusCodeValidator: ResponseValidating, @unchecked Sendable {
    private let _validator: AFNetworking.AFStatusCodeValidator

    public var acceptableStatusCodes: IndexSet {
        _validator.acceptableStatusCodes as IndexSet
    }

    public init(acceptableStatusCodes: IndexSet) {
        _validator = AFNetworking.AFStatusCodeValidator(acceptableStatusCodes: acceptableStatusCodes)
    }

    public static func `default`() -> StatusCodeValidator {
        StatusCodeValidator(acceptableStatusCodes: IndexSet(integersIn: 200..<300))
    }

    public func validate(_ request: URLRequest?, response: HTTPURLResponse, data: Data?) -> NSError? {
        _validator.validate(request, response: response, data: data) as NSError?
    }
}

// MARK: - ContentTypeValidator

/// 验证响应 Content-Type 是否在可接受范围内。底层委托给 OC `AFContentTypeValidator`。
public struct ContentTypeValidator: ResponseValidating, @unchecked Sendable {
    private let _validator: AFNetworking.AFContentTypeValidator

    public var acceptableContentTypes: Set<String> {
        _validator.acceptableContentTypes as Set<String>
    }

    public init(acceptableContentTypes: Set<String>) {
        _validator = AFNetworking.AFContentTypeValidator(acceptableContentTypes: acceptableContentTypes)
    }

    public func validate(_ request: URLRequest?, response: HTTPURLResponse, data: Data?) -> NSError? {
        _validator.validate(request, response: response, data: data) as NSError?
    }
}

// MARK: - BlockResponseValidator

/// 使用 block 实现自定义验证逻辑。底层委托给 OC `AFBlockResponseValidator`。
public struct BlockResponseValidator: ResponseValidating, @unchecked Sendable {
    public typealias ValidationBlock = @Sendable (URLRequest?, HTTPURLResponse, Data?) -> NSError?

    private let _validator: AFNetworking.AFBlockResponseValidator

    public init(block: @escaping ValidationBlock) {
        _validator = AFNetworking.AFBlockResponseValidator { request, response, data in
            block(request, response, data)
        }
    }

    public func validate(_ request: URLRequest?, response: HTTPURLResponse, data: Data?) -> NSError? {
        _validator.validate(request, response: response, data: data) as NSError?
    }
}

// MARK: - Error Constants (re-exported from OC layer)

// 这些常量已在 OC 层 AFResponseValidator.h 中定义并自动桥接到 Swift。
// 为了保持 Swift 层 API 兼容性，提供 Swift 别名：

/// 响应验证错误域
public let ResponseValidationErrorDomain = AFNetworking.AFResponseValidationErrorDomain

/// 响应验证错误码
public enum ResponseValidationError: Int {
    case unacceptableStatusCode = -1000
    case unacceptableContentType = -1001
    case customValidationFailed = -1002
}

/// 验证错误 userInfo keys
public let ResponseValidationErrorStatusCodeKey = AFNetworking.AFResponseValidationErrorStatusCodeKey
public let ResponseValidationErrorAcceptableStatusCodesKey = AFNetworking.AFResponseValidationErrorAcceptableStatusCodesKey
public let ResponseValidationErrorContentTypeKey = AFNetworking.AFResponseValidationErrorContentTypeKey
public let ResponseValidationErrorAcceptableContentTypesKey = AFNetworking.AFResponseValidationErrorAcceptableContentTypesKey
