// ParameterEncoder.swift
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

// MARK: - ParameterEncoder Protocol

/// 现代参数编码协议，对齐 Alamofire 的 `ParameterEncoder`。
/// 接受 `Encodable` 类型参数，将其编码到 `URLRequest` 中。
///
/// 与传统 `ParameterEncoding` 枚举（接受 `[String: Any]`）互补：
/// - `ParameterEncoding`：传统 OC 字典参数
/// - `ParameterEncoder`：现代 Swift `Encodable` 参数
public protocol ParameterEncoder: Sendable {
    /// 将 `Encodable` 参数编码到请求中
    func encode<Parameters: Encodable>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest
}

// MARK: - JSONParameterEncoder

/// JSON 参数编码器，对齐 Alamofire 的 `JSONParameterEncoder`。
/// 将 `Encodable` 参数编码为 JSON 请求体。
///
/// 用法：
/// ```swift
/// struct Login: Encodable { let username: String; let password: String }
/// session.request(url, method: .post, parameters: Login(username: "a", password: "b"), encoder: .json)
/// ```
public struct JSONParameterEncoder: ParameterEncoder {

    /// 默认实例
    public static let `default` = JSONParameterEncoder()

    /// 使用 prettyPrinted 输出的实例
    public static let prettyPrinted = JSONParameterEncoder(encoder: {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }())

    /// 使用 sortedKeys 输出的实例
    public static let sortedKeys: JSONParameterEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return JSONParameterEncoder(encoder: encoder)
    }()

    /// 底层 JSON 编码器
    public let encoder: JSONEncoder

    /// Content-Type 值
    public let contentType: String

    public init(encoder: JSONEncoder = JSONEncoder(), contentType: String = "application/json") {
        self.encoder = encoder
        self.contentType = contentType
    }

    public func encode<Parameters: Encodable>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest {
        guard let parameters else { return request }

        var request = request
        request.httpBody = try encoder.encode(parameters)

        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}

// MARK: - URLEncodedFormParameterEncoder

/// URL 编码表单参数编码器，对齐 Alamofire 的 `URLEncodedFormParameterEncoder`。
/// 将 `Encodable` 参数编码为 URL 查询字符串或表单请求体。
///
/// 用法：
/// ```swift
/// struct Search: Encodable { let q: String; let page: Int }
/// session.request(url, parameters: Search(q: "swift", page: 1), encoder: .urlEncodedForm)
/// ```
public struct URLEncodedFormParameterEncoder: ParameterEncoder {

    /// 参数编码位置
    public enum Destination: Sendable {
        /// 根据 HTTP 方法自动选择：GET/HEAD/DELETE 放 URL，其他放 Body
        case methodDependent
        /// 强制放入 URL 查询参数
        case queryString
        /// 强制放入 HTTP Body
        case httpBody
    }

    /// 默认实例
    public static let `default` = URLEncodedFormParameterEncoder()

    /// 参数放置位置
    public let destination: Destination

    public init(destination: Destination = .methodDependent) {
        self.destination = destination
    }

    public func encode<Parameters: Encodable>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest {
        guard let parameters else { return request }

        var request = request

        // 将 Encodable 转为字典，再转为 URL 编码字符串
        let dictionary = try encodableToDictionary(parameters)
        let queryString = Self.urlEncodedString(from: dictionary)

        let shouldEncodeInURL: Bool
        switch destination {
        case .queryString:
            shouldEncodeInURL = true
        case .httpBody:
            shouldEncodeInURL = false
        case .methodDependent:
            let method = request.httpMethod?.uppercased() ?? "GET"
            shouldEncodeInURL = ["GET", "HEAD", "DELETE"].contains(method)
        }

        if shouldEncodeInURL {
            if var components = request.url.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }) {
                let existingQuery = components.percentEncodedQuery.map { $0 + "&" } ?? ""
                components.percentEncodedQuery = existingQuery + queryString
                request.url = components.url
            }
        } else {
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }
            request.httpBody = Data(queryString.utf8)
        }

        return request
    }

    // MARK: - Internal

    /// 将 Encodable 转为 [String: Any] 字典
    private func encodableToDictionary<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AFError.responseSerializationFailed(reason: "Failed to convert Encodable to dictionary")
        }
        return dictionary
    }

    /// 将字典转为 URL 编码的查询字符串
    static func urlEncodedString(from dictionary: [String: Any]) -> String {
        dictionary.sorted { $0.key < $1.key }
            .map { key, value in
                let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? key
                let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? "\(value)"
                return "\(escapedKey)=\(escapedValue)"
            }
            .joined(separator: "&")
    }
}

// MARK: - CharacterSet Extension

private extension CharacterSet {
    /// RFC 3986 允许的 URL 查询字符集
    static let afURLQueryAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=")
        return allowed
    }()
}

// MARK: - Convenience aliases

extension ParameterEncoder where Self == JSONParameterEncoder {
    /// JSON 编码器便利工厂
    public static var json: JSONParameterEncoder { .default }
}

extension ParameterEncoder where Self == URLEncodedFormParameterEncoder {
    /// URL 编码表单便利工厂
    public static var urlEncodedForm: URLEncodedFormParameterEncoder { .default }
}
