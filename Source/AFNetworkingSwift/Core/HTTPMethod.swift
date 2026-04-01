// HTTPMethod.swift
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

/// HTTP 请求方法的类型安全封装，对齐 Alamofire 的 `HTTPMethod`。
public struct HTTPMethod: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// HTTP GET
    public static let GET = HTTPMethod(rawValue: "GET")
    /// HTTP HEAD
    public static let HEAD = HTTPMethod(rawValue: "HEAD")
    /// HTTP POST
    public static let POST = HTTPMethod(rawValue: "POST")
    /// HTTP PUT
    public static let PUT = HTTPMethod(rawValue: "PUT")
    /// HTTP PATCH
    public static let PATCH = HTTPMethod(rawValue: "PATCH")
    /// HTTP DELETE
    public static let DELETE = HTTPMethod(rawValue: "DELETE")
    /// HTTP CONNECT
    public static let CONNECT = HTTPMethod(rawValue: "CONNECT")
    /// HTTP OPTIONS
    public static let OPTIONS = HTTPMethod(rawValue: "OPTIONS")
    /// HTTP TRACE
    public static let TRACE = HTTPMethod(rawValue: "TRACE")
}

extension HTTPMethod: CustomStringConvertible {
    public var description: String { rawValue }
}
