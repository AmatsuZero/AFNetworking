// URLConvertible.swift
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

// MARK: - URLConvertible

/// 类型安全的 URL 转换协议，对齐 Alamofire 的 `URLConvertible`。
/// 让 `String`、`URL`、`URLComponents` 都可以作为请求 URL 参数。
public protocol URLConvertible: Sendable {
    /// 将自身转换为 `URL`，失败时抛出错误。
    func asURL() throws -> URL
}

extension String: URLConvertible {
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else {
            throw AFError.invalidURL(url: self)
        }
        return url
    }
}

extension URL: URLConvertible {
    public func asURL() throws -> URL { self }
}

extension URLComponents: URLConvertible {
    public func asURL() throws -> URL {
        guard let url = self.url else {
            throw AFError.invalidURL(url: self.string ?? "")
        }
        return url
    }
}

// MARK: - URLRequestConvertible

/// 类型安全的 URLRequest 转换协议，对齐 Alamofire 的 `URLRequestConvertible`。
public protocol URLRequestConvertible: Sendable {
    /// 将自身转换为 `URLRequest`，失败时抛出错误。
    func asURLRequest() throws -> URLRequest
}

extension URLRequest: URLRequestConvertible {
    public func asURLRequest() throws -> URLRequest { self }
}
