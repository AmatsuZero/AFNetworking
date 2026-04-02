// HTTPHeaders.swift
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

// MARK: - HTTPHeader (Swift wrapper around AFHTTPHeader)

/// 单个 HTTP 头字段的名值对，对齐 Alamofire 的 `HTTPHeader`。
/// 底层实现委托给 OC 层 `AFHTTPHeader`。
public struct HTTPHeader: Hashable, Sendable {
    /// 底层 OC 对象
    public let storage: AFHTTPHeader

    /// 头字段名称
    public var name: String { storage.name }
    /// 头字段值
    public var value: String { storage.value }

    /// 使用名称和值创建头字段
    public init(name: String, value: String) {
        self.storage = AFHTTPHeader(name: name, value: value)
    }

    /// 从 OC 对象创建
    public init(_ header: AFHTTPHeader) {
        self.storage = header
    }

    // MARK: - 常用头字段便利构造

    public static func accept(_ value: String) -> HTTPHeader {
        HTTPHeader(.accept(value))
    }

    public static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(.contentType(value))
    }

    public static func authorization(_ value: String) -> HTTPHeader {
        HTTPHeader(.authorization(value))
    }

    public static func authorization(bearerToken: String) -> HTTPHeader {
        HTTPHeader(.bearerAuthorization(bearerToken))
    }

    public static func authorization(username: String, password: String) -> HTTPHeader {
        HTTPHeader(.basicAuthorization(withUsername: username, password: password))
    }

    public static func userAgent(_ value: String) -> HTTPHeader {
        HTTPHeader(.userAgent(value))
    }

    // MARK: - Hashable (case-insensitive name)

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name.lowercased())
        hasher.combine(value)
    }

    public static func == (lhs: HTTPHeader, rhs: HTTPHeader) -> Bool {
        lhs.name.lowercased() == rhs.name.lowercased() && lhs.value == rhs.value
    }
}

extension HTTPHeader: CustomStringConvertible {
    public var description: String { "\(name): \(value)" }
}

// MARK: - HTTPHeaders (Swift wrapper around AFHTTPHeaders)

/// 有序 HTTP 头字段集合，对齐 Alamofire 的 `HTTPHeaders`。
/// 底层实现委托给 OC 层 `AFHTTPHeaders`，Swift 层添加值语义和协议适配。
public struct HTTPHeaders: Sendable {

    /// 底层 OC 对象
    internal var _storage: AFHTTPHeaders

    /// 从 OC 对象创建
    internal init(storage: AFHTTPHeaders) {
        _storage = storage
    }

    /// 所有头字段的有序数组
    public var headers: [HTTPHeader] {
        _storage.allHeaders.map { HTTPHeader($0) }
    }

    /// 以字典形式返回所有头字段（同名取最后一个值）
    public var dictionary: [String: String] {
        _storage.dictionary as [String: String]
    }

    /// 头字段数量
    public var count: Int { Int(_storage.count) }

    // MARK: - 初始化

    public init() {
        _storage = AFHTTPHeaders()
    }

    public init(headers: [HTTPHeader]) {
        _storage = AFHTTPHeaders()
        for header in headers {
            _storage.add(header.storage)
        }
    }

    public init(dictionary: [String: String]) {
        _storage = AFHTTPHeaders(dictionary: dictionary)
    }

    // MARK: - 增删改查 (copy-on-write via mutableCopy)

    private mutating func ensureUnique() {
        _storage = _storage.copy() as! AFHTTPHeaders
    }

    public mutating func add(_ header: HTTPHeader) {
        ensureUnique()
        _storage.add(header.storage)
    }

    public mutating func add(name: String, value: String) {
        ensureUnique()
        _storage.addName(name, value: value)
    }

    public mutating func remove(name: String) {
        ensureUnique()
        _storage.removeHeader(forName: name)
    }

    public func value(for name: String) -> String? {
        _storage.value(forHeaderName: name)
    }

    public func header(for name: String) -> HTTPHeader? {
        guard let h = _storage.header(forName: name) else { return nil }
        return HTTPHeader(h)
    }

    public func apply(to request: inout URLRequest) {
        let mutable = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        _storage.apply(to: mutable)
        request = mutable as URLRequest
    }

    // MARK: - 默认头

    public static var `default`: HTTPHeaders {
        var result = HTTPHeaders()
        result._storage = AFHTTPHeaders.default()
        return result
    }
}

extension HTTPHeaders: Sequence {
    public func makeIterator() -> IndexingIterator<[HTTPHeader]> {
        headers.makeIterator()
    }
}

extension HTTPHeaders: Collection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }
    public subscript(position: Int) -> HTTPHeader { headers[position] }
    public func index(after i: Int) -> Int { i + 1 }
}

extension HTTPHeaders: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        _storage = AFHTTPHeaders()
        for (name, value) in elements {
            _storage.addName(name, value: value)
        }
    }
}

extension HTTPHeaders: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: HTTPHeader...) {
        self.init(headers: elements)
    }
}

extension HTTPHeaders: CustomStringConvertible {
    public var description: String {
        headers.map { $0.description }.joined(separator: "\n")
    }
}
