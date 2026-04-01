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
#endif

/// Data 请求类型，对齐 Alamofire 的 `DataRequest`。
public final class DataRequest: Request, @unchecked Sendable {

    /// 共享默认 JSON 解码器，避免每次调用重新分配
    private static let defaultDecoder = JSONDecoder()

    /// 已收集的响应数据
    public var data: Data? { context.data }

    // MARK: - 响应处理（通用骨架）

    /// 通用响应处理骨架：注册完成回调 → 验证 → 序列化 → 构建 DataResponse → 分发。
    /// 所有公开 response* 方法复用此方法消除重复。
    private func appendResponseSerializer<T>(
        queue: DispatchQueue?,
        serialize: @escaping @Sendable (_ data: Data?, _ error: Error?) -> Result<T, Error>,
        completionHandler: @escaping @Sendable (DataResponse<T>) -> Void
    ) {
        session?.registerCompletion(for: self) { [self] in
            let data = self.context.data                       // read once
            let validationError = self.performValidation()
            let finalError = validationError ?? self.context.error
            let result = serialize(data, finalError)

            let response = DataResponse<T>(
                request: self.context.currentRequest,
                response: self.context.response,
                data: data,
                metrics: self.metricsIfAvailable,
                serializationDuration: 0,
                result: result
            )
            self.dispatchCallback(on: queue) { completionHandler(response) }
        }
    }

    // MARK: - 公开响应方法

    /// 原始响应回调（不做序列化）
    @discardableResult
    public func response(queue: DispatchQueue? = nil,
                         completionHandler: @escaping @Sendable (DataResponse<Data?>) -> Void) -> Self {
        appendResponseSerializer(queue: queue, serialize: { data, error in
            error == nil ? .success(data) : .failure(error!)
        }, completionHandler: completionHandler)
        return self
    }

    /// Data 响应回调
    @discardableResult
    public func responseData(queue: DispatchQueue? = nil,
                             completionHandler: @escaping @Sendable (DataResponse<Data>) -> Void) -> Self {
        appendResponseSerializer(queue: queue, serialize: { data, error in
            if let error = error { return .failure(error) }
            return .success(data ?? Data())
        }, completionHandler: completionHandler)
        return self
    }

    /// String 响应回调
    @discardableResult
    public func responseString(queue: DispatchQueue? = nil,
                               encoding: String.Encoding = .utf8,
                               completionHandler: @escaping @Sendable (DataResponse<String>) -> Void) -> Self {
        appendResponseSerializer(queue: queue, serialize: { data, error in
            if let error = error { return .failure(error) }
            if let data = data, let string = String(data: data, encoding: encoding) {
                return .success(string)
            }
            return .success("")
        }, completionHandler: completionHandler)
        return self
    }

    /// JSON 响应回调
    @discardableResult
    public func responseJSON(queue: DispatchQueue? = nil,
                             options: JSONSerialization.ReadingOptions = .allowFragments,
                             completionHandler: @escaping @Sendable (DataResponse<Any>) -> Void) -> Self {
        appendResponseSerializer(queue: queue, serialize: { data, error in
            if let error = error { return .failure(error) }
            guard let data = data, !data.isEmpty else {
                return .failure(AFError.responseSerializationFailed(reason: "Response data was empty"))
            }
            do {
                return .success(try JSONSerialization.jsonObject(with: data, options: options))
            } catch {
                return .failure(error)
            }
        }, completionHandler: completionHandler)
        return self
    }

    /// Decodable 模型响应回调
    @discardableResult
    public func responseDecodable<T: Decodable & Sendable>(of type: T.Type = T.self,
                                                queue: DispatchQueue? = nil,
                                                decoder: JSONDecoder? = nil,
                                                completionHandler: @escaping @Sendable (DataResponse<T>) -> Void) -> Self {
        let decoder = decoder ?? Self.defaultDecoder
        appendResponseSerializer(queue: queue, serialize: { data, error in
            if let error = error { return .failure(error) }
            guard let data = data else {
                return .failure(AFError.responseSerializationFailed(reason: "Response data was nil"))
            }
            do {
                return .success(try decoder.decode(T.self, from: data))
            } catch {
                return .failure(error)
            }
        }, completionHandler: completionHandler)
        return self
    }
}
