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

// MARK: - HTTPHeader

/// 单个 HTTP 头字段的名值对，对齐 Alamofire 的 `HTTPHeader`。
public struct HTTPHeader: Hashable, Sendable {
    /// 头字段名称
    public let name: String
    /// 头字段值
    public let value: String

    /// 使用名称和值创建头字段
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    // MARK: - 常用头字段便利构造

    /// 创建 Accept 头
    public static func accept(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept", value: value)
    }

    /// 创建 Content-Type 头
    public static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }

    /// 创建 Authorization 头
    public static func authorization(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: value)
    }

    /// 创建 Bearer Token Authorization 头
    public static func authorization(bearerToken: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: "Bearer \(bearerToken)")
    }

    /// 创建 Basic Authorization 头
    public static func authorization(username: String, password: String) -> HTTPHeader {
        let credential = Data("\(username):\(password)".utf8).base64EncodedString()
        return HTTPHeader(name: "Authorization", value: "Basic \(credential)")
    }

    /// 创建 User-Agent 头
    public static func userAgent(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "User-Agent", value: value)
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

// MARK: - HTTPHeaders

/// 有序 HTTP 头字段集合，对齐 Alamofire 的 `HTTPHeaders`。
/// 值语义 struct，保持插入顺序并支持按名称去重。
public struct HTTPHeaders: Sendable {

    /// 内部有序头字段数组
    private var _headers: [HTTPHeader] = []

    /// 所有头字段的有序数组
    public var headers: [HTTPHeader] { _headers }

    /// 以字典形式返回所有头字段（同名取最后一个值）
    public var dictionary: [String: String] {
        var dict = [String: String]()
        for header in _headers {
            dict[header.name] = header.value
        }
        return dict
    }

    /// 头字段数量
    public var count: Int { _headers.count }

    // MARK: - 初始化

    /// 创建空的头集合
    public init() {}

    /// 从头字段数组创建（同名字段后者覆盖前者）
    public init(headers: [HTTPHeader]) {
        for header in headers {
            add(header)
        }
    }

    /// 从字典创建
    public init(dictionary: [String: String]) {
        for (name, value) in dictionary.sorted(by: { $0.key < $1.key }) {
            _headers.append(HTTPHeader(name: name, value: value))
        }
    }

    // MARK: - 增删改查

    /// 添加或更新头字段（同名覆盖）
    public mutating func add(_ header: HTTPHeader) {
        if let index = _headers.firstIndex(where: { $0.name.lowercased() == header.name.lowercased() }) {
            _headers[index] = header
        } else {
            _headers.append(header)
        }
    }

    /// 添加或更新头字段
    public mutating func add(name: String, value: String) {
        add(HTTPHeader(name: name, value: value))
    }

    /// 移除指定名称的头字段
    public mutating func remove(name: String) {
        _headers.removeAll { $0.name.lowercased() == name.lowercased() }
    }

    /// 按名称查找头字段值
    public func value(for name: String) -> String? {
        _headers.first { $0.name.lowercased() == name.lowercased() }?.value
    }

    /// 按名称查找头字段
    public func header(for name: String) -> HTTPHeader? {
        _headers.first { $0.name.lowercased() == name.lowercased() }
    }

    /// 对指定 URLRequest 应用所有头字段
    public func apply(to request: inout URLRequest) {
        for header in _headers {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
    }

    // MARK: - 默认头

    /// 默认头集合，包含 Accept-Encoding、Accept-Language 和 User-Agent
    public static var `default`: HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(HTTPHeader(name: "Accept-Encoding", value: "br;q=1.0, gzip;q=0.9, deflate;q=0.8"))

        let preferredLanguages = Locale.preferredLanguages.prefix(6)
        let languageQuality: [String] = preferredLanguages.enumerated().map { index, language in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(language);q=\(String(format: "%.1f", quality))"
        }
        headers.add(HTTPHeader(name: "Accept-Language", value: languageQuality.joined(separator: ", ")))

        return headers
    }
}

extension HTTPHeaders: Sequence {
    public func makeIterator() -> IndexingIterator<[HTTPHeader]> {
        _headers.makeIterator()
    }
}

extension HTTPHeaders: Collection {
    public var startIndex: Int { _headers.startIndex }
    public var endIndex: Int { _headers.endIndex }
    public subscript(position: Int) -> HTTPHeader { _headers[position] }
    public func index(after i: Int) -> Int { _headers.index(after: i) }
}

extension HTTPHeaders: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        for (name, value) in elements {
            _headers.append(HTTPHeader(name: name, value: value))
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
        _headers.map { $0.description }.joined(separator: "\n")
    }
}
