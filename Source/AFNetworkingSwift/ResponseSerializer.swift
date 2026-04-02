// ResponseSerializer.swift
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

// MARK: - DataPreprocessor

/// 数据预处理协议，在序列化前对原始数据进行转换。
/// 对齐 Alamofire 的 `DataPreprocessor`。
public protocol DataPreprocessor: Sendable {
    func preprocess(_ data: Data) throws -> Data
}

/// 直通预处理器，不做任何转换。
public struct PassthroughPreprocessor: DataPreprocessor {
    public init() {}
    public func preprocess(_ data: Data) throws -> Data { data }
}

/// Google XSSI 预处理器，移除 `)]}'` 前缀。
public struct GoogleXSSIPreprocessor: DataPreprocessor {
    public init() {}
    public func preprocess(_ data: Data) throws -> Data {
        guard data.count >= 6 else { return data }
        let prefix = String(data: data.prefix(6), encoding: .utf8) ?? ""
        if prefix.hasPrefix(")]}'") {
            // 找到第一个换行符后的内容
            if let newlineIndex = data.firstIndex(of: UInt8(ascii: "\n")) {
                return data.suffix(from: data.index(after: newlineIndex))
            }
        }
        return data
    }
}

// MARK: - EmptyResponse

/// 空响应协议，对齐 Alamofire 的 `EmptyResponse`。
public protocol EmptyResponse {
    static func emptyValue() -> Self
}

/// 空响应默认实现。
public struct Empty: Codable, EmptyResponse {
    public static func emptyValue() -> Empty { Empty() }
    public init() {}
}

// MARK: - DataDecoder

/// 数据解码器协议，对齐 Alamofire 的 `DataDecoder`。
public protocol DataDecoder: Sendable {
    func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D
}

extension JSONDecoder: DataDecoder {}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension PropertyListDecoder: DataDecoder {}

// MARK: - DataResponseSerializerProtocol

/// 数据响应序列化协议，对齐 Alamofire 的 `DataResponseSerializerProtocol`。
public protocol DataResponseSerializerProtocol: Sendable {
    associatedtype SerializedObject: Sendable
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: (any Error)?) throws -> SerializedObject
}

// MARK: - DownloadResponseSerializerProtocol

/// 下载响应序列化协议，对齐 Alamofire 的 `DownloadResponseSerializerProtocol`。
public protocol DownloadResponseSerializerProtocol: Sendable {
    associatedtype SerializedObject: Sendable
    func serializeDownload(request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: (any Error)?) throws -> SerializedObject
}

// MARK: - ResponseSerializer

/// 同时遵循 Data 和 Download 序列化协议的组合协议，对齐 Alamofire 的 `ResponseSerializer`。
public protocol ResponseSerializer: DataResponseSerializerProtocol & DownloadResponseSerializerProtocol {
    /// 数据预处理器
    var dataPreprocessor: any DataPreprocessor { get }
    /// 空响应的 HTTP 状态码（如 204）
    var emptyResponseCodes: Set<Int> { get }
    /// 空响应的 HTTP 方法（如 HEAD）
    var emptyRequestMethods: Set<String> { get }
}

extension ResponseSerializer {
    public var dataPreprocessor: any DataPreprocessor { PassthroughPreprocessor() }
    public var emptyResponseCodes: Set<Int> { [204, 205] }
    public var emptyRequestMethods: Set<String> { ["HEAD"] }

    /// 判断是否为空响应（根据状态码或方法）
    public func requestAllowsEmptyResponseData(_ request: URLRequest?) -> Bool {
        guard let method = request?.httpMethod else { return false }
        return emptyRequestMethods.contains(method)
    }

    public func responseAllowsEmptyResponseData(_ response: HTTPURLResponse?) -> Bool {
        guard let code = response?.statusCode else { return false }
        return emptyResponseCodes.contains(code)
    }
}

// MARK: - DataResponseSerializer

/// 原始 Data 序列化器。
public struct DataResponseSerializer: ResponseSerializer {
    public let dataPreprocessor: any DataPreprocessor
    public let emptyResponseCodes: Set<Int>
    public let emptyRequestMethods: Set<String>

    public init(dataPreprocessor: any DataPreprocessor = PassthroughPreprocessor(),
                emptyResponseCodes: Set<Int> = [204, 205],
                emptyRequestMethods: Set<String> = ["HEAD"]) {
        self.dataPreprocessor = dataPreprocessor
        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
    }

    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: (any Error)?) throws -> Data {
        if let error { throw error }

        if requestAllowsEmptyResponseData(request) || responseAllowsEmptyResponseData(response) {
            return data ?? Data()
        }

        guard let data, !data.isEmpty else {
            throw AFError.responseSerializationFailed(reason: "Response data was empty")
        }

        return try dataPreprocessor.preprocess(data)
    }

    public func serializeDownload(request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: (any Error)?) throws -> Data {
        if let error { throw error }

        if requestAllowsEmptyResponseData(request) || responseAllowsEmptyResponseData(response) {
            if let fileURL { return (try? Data(contentsOf: fileURL)) ?? Data() }
            return Data()
        }

        guard let fileURL else {
            throw AFError.responseSerializationFailed(reason: "Download fileURL was nil")
        }

        return try dataPreprocessor.preprocess(try Data(contentsOf: fileURL))
    }
}

// MARK: - StringResponseSerializer

/// 字符串序列化器。
public struct StringResponseSerializer: ResponseSerializer {
    public let dataPreprocessor: any DataPreprocessor
    public let encoding: String.Encoding
    public let emptyResponseCodes: Set<Int>
    public let emptyRequestMethods: Set<String>

    public init(dataPreprocessor: any DataPreprocessor = PassthroughPreprocessor(),
                encoding: String.Encoding = .utf8,
                emptyResponseCodes: Set<Int> = [204, 205],
                emptyRequestMethods: Set<String> = ["HEAD"]) {
        self.dataPreprocessor = dataPreprocessor
        self.encoding = encoding
        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
    }

    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: (any Error)?) throws -> String {
        if let error { throw error }

        if requestAllowsEmptyResponseData(request) || responseAllowsEmptyResponseData(response) {
            return ""
        }

        guard let data, !data.isEmpty else {
            throw AFError.responseSerializationFailed(reason: "Response data was empty")
        }

        let preprocessed = try dataPreprocessor.preprocess(data)
        guard let string = String(data: preprocessed, encoding: encoding) else {
            throw AFError.responseSerializationFailed(reason: "String could not be created with encoding \(encoding)")
        }
        return string
    }

    public func serializeDownload(request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: (any Error)?) throws -> String {
        if let error { throw error }

        if requestAllowsEmptyResponseData(request) || responseAllowsEmptyResponseData(response) {
            return ""
        }

        guard let fileURL else {
            throw AFError.responseSerializationFailed(reason: "Download fileURL was nil")
        }

        let data = try dataPreprocessor.preprocess(try Data(contentsOf: fileURL))
        guard let string = String(data: data, encoding: encoding) else {
            throw AFError.responseSerializationFailed(reason: "String could not be created with encoding \(encoding)")
        }
        return string
    }
}

// MARK: - DecodableResponseSerializer

/// Decodable 模型序列化器，对齐 Alamofire 的 `DecodableResponseSerializer`。
public struct DecodableResponseSerializer<T: Decodable & Sendable>: ResponseSerializer {
    public let dataPreprocessor: any DataPreprocessor
    public let decoder: any DataDecoder
    public let emptyResponseCodes: Set<Int>
    public let emptyRequestMethods: Set<String>

    public init(dataPreprocessor: any DataPreprocessor = PassthroughPreprocessor(),
                decoder: any DataDecoder = JSONDecoder(),
                emptyResponseCodes: Set<Int> = [204, 205],
                emptyRequestMethods: Set<String> = ["HEAD"]) {
        self.dataPreprocessor = dataPreprocessor
        self.decoder = decoder
        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
    }

    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: (any Error)?) throws -> T {
        if let error { throw error }

        if requestAllowsEmptyResponseData(request) || responseAllowsEmptyResponseData(response) {
            guard let emptyType = T.self as? EmptyResponse.Type, let emptyValue = emptyType.emptyValue() as? T else {
                throw AFError.responseSerializationFailed(reason: "Empty response but type \(T.self) does not conform to EmptyResponse")
            }
            return emptyValue
        }

        guard let data, !data.isEmpty else {
            throw AFError.responseSerializationFailed(reason: "Response data was empty")
        }

        let preprocessed = try dataPreprocessor.preprocess(data)
        return try decoder.decode(T.self, from: preprocessed)
    }

    public func serializeDownload(request: URLRequest?, response: HTTPURLResponse?, fileURL: URL?, error: (any Error)?) throws -> T {
        if let error { throw error }

        if requestAllowsEmptyResponseData(request) || responseAllowsEmptyResponseData(response) {
            guard let emptyType = T.self as? EmptyResponse.Type, let emptyValue = emptyType.emptyValue() as? T else {
                throw AFError.responseSerializationFailed(reason: "Empty response but type \(T.self) does not conform to EmptyResponse")
            }
            return emptyValue
        }

        guard let fileURL else {
            throw AFError.responseSerializationFailed(reason: "Download fileURL was nil")
        }

        let data = try dataPreprocessor.preprocess(try Data(contentsOf: fileURL))
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - DataRequest + ResponseSerializer

extension DataRequest {

    /// 使用自定义序列化器处理响应，对齐 Alamofire 的 `response(responseSerializer:)`.
    @discardableResult
    public func response<Serializer: DataResponseSerializerProtocol>(
        queue: DispatchQueue? = nil,
        responseSerializer: Serializer,
        completionHandler: @escaping @Sendable (DataResponse<Serializer.SerializedObject>) -> Void
    ) -> Self {
        session?.registerCompletion(for: self) { [self] in
            let data = self.context.data
            let validationError = self.performValidation()
            let finalError = validationError ?? self.context.error
            let result: Result<Serializer.SerializedObject, Error>
            do {
                let value = try responseSerializer.serialize(
                    request: self.context.currentRequest,
                    response: self.context.response,
                    data: data,
                    error: finalError
                )
                result = .success(value)
            } catch {
                result = .failure(error)
            }

            let response = DataResponse<Serializer.SerializedObject>(
                request: self.context.currentRequest,
                response: self.context.response,
                data: data,
                metrics: self.metricsIfAvailable,
                serializationDuration: 0,
                result: result
            )
            self.dispatchCallback(on: queue) { completionHandler(response) }
        }
        return self
    }
}

// MARK: - DownloadRequest + ResponseSerializer

extension DownloadRequest {

    /// 使用自定义序列化器处理下载响应，对齐 Alamofire 的 `response(responseSerializer:)`.
    @discardableResult
    public func response<Serializer: DownloadResponseSerializerProtocol>(
        queue: DispatchQueue? = nil,
        responseSerializer: Serializer,
        completionHandler: @escaping @Sendable (DownloadResponse<Serializer.SerializedObject>) -> Void
    ) -> Self {
        session?.registerDownloadCompletion(for: self) { [self] in
            let validationError = self.performValidation(data: nil)
            let finalError = validationError ?? self.context.error
            let result: Result<Serializer.SerializedObject, Error>
            do {
                let value = try responseSerializer.serializeDownload(
                    request: self.context.currentRequest,
                    response: self.context.response,
                    fileURL: self.context.fileURL,
                    error: finalError
                )
                result = .success(value)
            } catch {
                result = .failure(error)
            }

            let response = DownloadResponse<Serializer.SerializedObject>(
                request: self.context.currentRequest,
                response: self.context.response,
                fileURL: self.context.fileURL,
                resumeData: nil,
                metrics: self.metricsIfAvailable,
                serializationDuration: 0,
                result: result
            )
            self.dispatchCallback(on: queue) { completionHandler(response) }
        }
        return self
    }
}
