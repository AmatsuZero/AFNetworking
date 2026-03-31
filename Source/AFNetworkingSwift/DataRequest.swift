// DataRequest.swift
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
import AFSwiftSupport
#endif

/// Data 请求类型，对齐 Alamofire 的 `DataRequest`。
public final class DataRequest: Request, @unchecked Sendable {

    /// 已收集的响应数据
    public var data: Data? { context.data }

    // MARK: - 响应处理

    /// 将回调分发到指定队列，若为 nil 则直接调用
    private func dispatchCallback(on queue: DispatchQueue?, execute work: @escaping @Sendable () -> Void) {
        if let queue = queue {
            queue.async { work() }
        } else {
            work()
        }
    }

    /// 原始响应回调（不做序列化）
    /// - Parameters:
    ///   - queue: 回调队列，nil 表示在当前队列直接回调
    ///   - completionHandler: 完成回调
    @discardableResult
    public func response(queue: DispatchQueue? = nil,
                         completionHandler: @escaping @Sendable (DataResponse<Data?>) -> Void) -> Self {
        session?.registerCompletion(for: self) { [weak self] in
            guard let self = self else { return }
            let validationError = self.performValidation()
            let finalError = validationError ?? self.context.error

            let response = DataResponse<Data?>(
                request: self.context.currentRequest as URLRequest?,
                response: self.context.response,
                data: self.context.data,
                metrics: self.metricsIfAvailable,
                serializationDuration: 0,
                result: finalError == nil ? .success(self.context.data) : .failure(finalError!)
            )
            self.dispatchCallback(on: queue) { completionHandler(response) }
        }
        return self
    }

    /// Data 响应回调
    /// - Parameters:
    ///   - queue: 回调队列，nil 表示在当前队列直接回调
    ///   - completionHandler: 完成回调
    @discardableResult
    public func responseData(queue: DispatchQueue? = nil,
                             completionHandler: @escaping @Sendable (DataResponse<Data>) -> Void) -> Self {
        session?.registerCompletion(for: self) { [weak self] in
            guard let self = self else { return }
            let validationError = self.performValidation()
            let finalError = validationError ?? self.context.error

            let result: Result<Data, Error>
            if let error = finalError {
                result = .failure(error)
            } else if let data = self.context.data {
                result = .success(data)
            } else {
                result = .success(Data())
            }

            let response = DataResponse<Data>(
                request: self.context.currentRequest as URLRequest?,
                response: self.context.response,
                data: self.context.data,
                metrics: self.metricsIfAvailable,
                serializationDuration: 0,
                result: result
            )
            self.dispatchCallback(on: queue) { completionHandler(response) }
        }
        return self
    }

    /// String 响应回调
    /// - Parameters:
    ///   - queue: 回调队列，nil 表示在当前队列直接回调
    ///   - encoding: 字符串编码，默认 .utf8
    ///   - completionHandler: 完成回调
    @discardableResult
    public func responseString(queue: DispatchQueue? = nil,
                               encoding: String.Encoding = .utf8,
                               completionHandler: @escaping @Sendable (DataResponse<String>) -> Void) -> Self {
        session?.registerCompletion(for: self) { [weak self] in
            guard let self = self else { return }
            let validationError = self.performValidation()
            let finalError = validationError ?? self.context.error

            let result: Result<String, Error>
            if let error = finalError {
                result = .failure(error)
            } else if let data = self.context.data, let string = String(data: data, encoding: encoding) {
                result = .success(string)
            } else {
                result = .success("")
            }

            let response = DataResponse<String>(
                request: self.context.currentRequest as URLRequest?,
                response: self.context.response,
                data: self.context.data,
                metrics: self.metricsIfAvailable,
                serializationDuration: 0,
                result: result
            )
            self.dispatchCallback(on: queue) { completionHandler(response) }
        }
        return self
    }

    /// JSON 响应回调
    /// - Parameters:
    ///   - queue: 回调队列，nil 表示在当前队列直接回调
    ///   - options: JSON 读取选项
    ///   - completionHandler: 完成回调
    @discardableResult
    public func responseJSON(queue: DispatchQueue? = nil,
                             options: JSONSerialization.ReadingOptions = .allowFragments,
                             completionHandler: @escaping @Sendable (DataResponse<Any>) -> Void) -> Self {
        session?.registerCompletion(for: self) { [weak self] in
            guard let self = self else { return }
            let validationError = self.performValidation()
            let finalError = validationError ?? self.context.error

            let result: Result<Any, Error>
            if let error = finalError {
                result = .failure(error)
            } else if let data = self.context.data, !data.isEmpty {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: options)
                    result = .success(json)
                } catch {
                    result = .failure(error)
                }
            } else {
                result = .failure(AFError.responseSerializationFailed(reason: "Response data was empty"))
            }

            let response = DataResponse<Any>(
                request: self.context.currentRequest as URLRequest?,
                response: self.context.response,
                data: self.context.data,
                metrics: self.metricsIfAvailable,
                serializationDuration: 0,
                result: result
            )
            self.dispatchCallback(on: queue) { completionHandler(response) }
        }
        return self
    }

    /// Decodable 模型响应回调
    /// - Parameters:
    ///   - type: 目标类型
    ///   - queue: 回调队列，nil 表示在当前队列直接回调
    ///   - decoder: JSON 解码器
    ///   - completionHandler: 完成回调
    @discardableResult
    public func responseDecodable<T: Decodable & Sendable>(of type: T.Type = T.self,
                                                queue: DispatchQueue? = nil,
                                                decoder: JSONDecoder = JSONDecoder(),
                                                completionHandler: @escaping @Sendable (DataResponse<T>) -> Void) -> Self {
        session?.registerCompletion(for: self) { [weak self] in
            guard let self = self else { return }
            let validationError = self.performValidation()
            let finalError = validationError ?? self.context.error

            let result: Result<T, Error>
            if let error = finalError {
                result = .failure(error)
            } else if let data = self.context.data {
                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    result = .success(decoded)
                } catch {
                    result = .failure(error)
                }
            } else {
                result = .failure(AFError.responseSerializationFailed(reason: "Response data was nil"))
            }

            let response = DataResponse<T>(
                request: self.context.currentRequest as URLRequest?,
                response: self.context.response,
                data: self.context.data,
                metrics: self.metricsIfAvailable,
                serializationDuration: 0,
                result: result
            )
            self.dispatchCallback(on: queue) { completionHandler(response) }
        }
        return self
    }

    // MARK: - 内部

    internal func performValidation() -> Error? {
        guard let httpResponse = context.response else { return nil }
        for validator in validators {
            if let error = validator.validate(context.currentRequest, response: httpResponse, data: context.data) {
                return error
            }
        }
        return nil
    }

    private var metricsIfAvailable: URLSessionTaskMetrics? {
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
            return context.metrics
        }
        return nil
    }
}
