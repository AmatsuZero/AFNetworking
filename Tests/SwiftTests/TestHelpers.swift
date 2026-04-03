//
//  TestHelpers.swift
//
//  Copyright (c) 2014-2018 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif

// MARK: - String Constants

extension String {
    static let invalidURL = "invalid"
    static let nonexistentDomain = "https://nonexistent-domain.org"
}

extension URL {
    static let nonexistentDomain = URL(string: .nonexistentDomain)!
}

// MARK: - Endpoint

/// 测试用端点，封装 URL 构建逻辑。
struct Endpoint {
    enum Scheme: String {
        case http, https

        var port: Int {
            switch self {
            case .http: 80
            case .https: 443
            }
        }
    }

    enum Host: String {
        case localhost = "127.0.0.1"
        case httpBin = "httpbin.org"

        func port(for scheme: Scheme) -> Int {
            switch self {
            case .localhost: 8080
            case .httpBin: scheme.port
            }
        }
    }

    enum Path {
        case basicAuth(username: String, password: String)
        case bytes(count: Int)
        case cache
        case chunked(count: Int)
        case compression(Compression)
        case delay(interval: Int)
        case digestAuth(qop: String, username: String, password: String)
        case download(count: Int)
        case stream(Int)
        case hiddenBasicAuth(username: String, password: String)
        case image(Image)
        case ip
        case method(HTTPMethod)
        case redirect(count: Int)
        case redirectTo
        case responseHeaders
        case status(Int)
        case xml

        var string: String {
            switch self {
            case let .basicAuth(username, password):
                "/basic-auth/\(username)/\(password)"
            case let .bytes(count):
                "/bytes/\(count)"
            case .cache:
                "/cache"
            case let .chunked(count):
                "/chunked/\(count)"
            case let .compression(compression):
                "/\(compression.rawValue)"
            case let .delay(interval):
                "/delay/\(interval)"
            case let .digestAuth(qop, username, password):
                "/digest-auth/\(qop)/\(username)/\(password)"
            case let .download(count):
                "/download/\(count)"
            case let .stream(count):
                "/stream/\(count)"
            case let .hiddenBasicAuth(username, password):
                "/hidden-basic-auth/\(username)/\(password)"
            case let .image(type):
                "/image/\(type.rawValue)"
            case .ip:
                "/ip"
            case let .method(method):
                "/\(method.rawValue.lowercased())"
            case let .redirect(count):
                "/redirect/\(count)"
            case .redirectTo:
                "/redirect-to"
            case .responseHeaders:
                "/response-headers"
            case let .status(code):
                "/status/\(code)"
            case .xml:
                "/xml"
            }
        }
    }

    enum Image: String {
        case jpeg
    }

    enum Compression: String {
        case brotli, gzip, deflate
    }

    // NOTE: HTTPMethod uses lowercase: .get, .post, etc.
    static var get: Endpoint { method(.get) }
    static var `default`: Endpoint { .get }

    static func basicAuth(forUser user: String = "user", password: String = "password") -> Endpoint {
        Endpoint(path: .basicAuth(username: user, password: password))
    }

    static func bytes(_ count: Int) -> Endpoint {
        Endpoint(path: .bytes(count: count))
    }

    static let cache: Endpoint = .init(path: .cache)

    static func compression(_ compression: Compression) -> Endpoint {
        Endpoint(path: .compression(compression))
    }

    static func delay(_ interval: Int) -> Endpoint {
        Endpoint(path: .delay(interval: interval))
    }

    static func digestAuth(forUser user: String = "user", password: String = "password") -> Endpoint {
        Endpoint(path: .digestAuth(qop: "auth", username: user, password: password))
    }

    static func hiddenBasicAuth(forUser user: String = "user", password: String = "password") -> Endpoint {
        Endpoint(path: .hiddenBasicAuth(username: user, password: password))
    }

    static func image(_ type: Image) -> Endpoint {
        Endpoint(path: .image(type))
    }

    static var ip: Endpoint {
        Endpoint(path: .ip)
    }

    static func method(_ method: HTTPMethod) -> Endpoint {
        Endpoint(path: .method(method), method: method)
    }

    static func redirect(_ count: Int) -> Endpoint {
        Endpoint(path: .redirect(count: count))
    }

    static func stream(_ count: Int) -> Endpoint {
        Endpoint(path: .stream(count))
    }

    static func redirectTo(_ url: String, code: Int? = nil) -> Endpoint {
        var items = [URLQueryItem(name: "url", value: url)]
        items = code.map { items + [.init(name: "statusCode", value: "\($0)")] } ?? items
        return Endpoint(path: .redirectTo, queryItems: items)
    }

    static var responseHeaders: Endpoint {
        Endpoint(path: .responseHeaders)
    }

    static func status(_ code: Int) -> Endpoint {
        Endpoint(path: .status(code))
    }

    static var xml: Endpoint {
        Endpoint(path: .xml)
    }

    var scheme = Scheme.http
    var port: Int { host.port(for: scheme) }
    var host = Host.localhost
    var path = Path.method(.get)
    var method: HTTPMethod = .get
    var headers: HTTPHeaders = .init()
    var timeout: TimeInterval = 60
    var queryItems: [URLQueryItem] = []
    var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy

    /// 构建 URLRequest
    func asURLRequest() throws -> URLRequest {
        var components = URLComponents()
        components.scheme = scheme.rawValue
        components.port = port
        components.host = host.rawValue
        components.path = path.string
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        for (name, value) in headers.dictionary {
            request.setValue(value, forHTTPHeaderField: name)
        }
        request.timeoutInterval = timeout
        request.cachePolicy = cachePolicy
        return request
    }

    /// URL 字符串，用于直接传给 Session.request
    var urlString: String {
        var components = URLComponents()
        components.scheme = scheme.rawValue
        components.port = port
        components.host = host.rawValue
        components.path = path.string
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url?.absoluteString ?? ""
    }

    /// URL for use in tests
    var url: URL {
        URL(string: urlString)!
    }

    /// URLRequest for use in serializer unit tests
    var urlRequest: URLRequest {
        (try? asURLRequest()) ?? URLRequest(url: url)
    }

    func modifying<T>(_ keyPath: WritableKeyPath<Endpoint, T>, to value: T) -> Endpoint {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
}

// MARK: - Session convenience extensions for Endpoint

extension Session {
    func request(_ endpoint: Endpoint,
                 parameters: [String: Any]? = nil,
                 interceptor: (any RequestInterceptor)? = nil) -> DataRequest {
        request(endpoint.urlString,
                method: endpoint.method,
                parameters: parameters,
                interceptor: interceptor)
    }

    func download(_ endpoint: Endpoint,
                  interceptor: (any RequestInterceptor)? = nil,
                  to destination: DownloadDestination? = nil) -> DownloadRequest {
        download(endpoint.urlString,
                 method: endpoint.method,
                 interceptor: interceptor,
                 to: destination)
    }

    func download(_ endpoint: Endpoint,
                  headers: HTTPHeaders,
                  interceptor: (any RequestInterceptor)? = nil,
                  to destination: DownloadDestination? = nil) -> DownloadRequest {
        download(endpoint.urlString,
                 method: endpoint.method,
                 headers: headers,
                 interceptor: interceptor,
                 to: destination)
    }

    /// Convenience for tests that have a pre-built URLRequest (e.g. CacheTests).
    func request(_ urlRequest: URLRequest) -> DataRequest {
        var headers: HTTPHeaders? = nil
        if let fields = urlRequest.allHTTPHeaderFields, !fields.isEmpty {
            headers = HTTPHeaders(dictionary: fields)
        }
        let method = HTTPMethod(rawValue: urlRequest.httpMethod ?? "GET")
        let urlString = urlRequest.url?.absoluteString ?? ""
        return request(urlString, method: method, headers: headers)
    }

    func streamRequest(_ endpoint: Endpoint,
                       automaticallyCancelOnStreamError: Bool = false,
                       interceptor: (any RequestInterceptor)? = nil) -> DataStreamRequest {
        streamRequest(endpoint.urlString,
                      method: endpoint.method,
                      headers: endpoint.headers.dictionary.isEmpty ? nil : endpoint.headers,
                      automaticallyCancelOnStreamError: automaticallyCancelOnStreamError,
                      interceptor: interceptor)
    }
}

// MARK: - Data Extensions

extension Data {
    var asString: String {
        String(decoding: self, as: UTF8.self)
    }

    func asJSONObject() throws -> Any {
        try JSONSerialization.jsonObject(with: self, options: .allowFragments)
    }
}

// MARK: - TestResponse

struct TestResponse: Decodable {
    let headers: [String: String]
    let origin: String
    let url: String
    let data: String?
    let form: [String: String]?
    let args: [String: String]
}

struct TestParameters: Encodable {
    static let `default` = TestParameters(property: "property")
    let property: String
}

// MARK: - HTTPURLResponse Convenience

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: URL(string: "https://httpbin.org")!,
                  statusCode: statusCode,
                  httpVersion: nil,
                  headerFields: nil)!
    }

    convenience init(statusCode: Int, headers: [String: String]) {
        self.init(url: URL(string: "https://httpbin.org")!,
                  statusCode: statusCode,
                  httpVersion: nil,
                  headerFields: headers)!
    }

    var headers: HTTPHeaders {
        HTTPHeaders(dictionary: (allHeaderFields as? [String: String]) ?? [:])
    }
}
