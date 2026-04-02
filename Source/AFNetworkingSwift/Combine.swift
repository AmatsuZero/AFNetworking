// Combine.swift
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

#if canImport(Combine)
import Combine
import Foundation
#if SWIFT_PACKAGE
import AFNetworking
#endif

// MARK: - DataResponsePublisher

/// Data 请求的 Combine Publisher，对齐 Alamofire 的 `DataResponsePublisher`。
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct DataResponsePublisher<Value: Sendable>: Publisher {
    public typealias Output = DataResponse<Value>
    public typealias Failure = Never

    private let request: DataRequest
    private let responseHandler: @Sendable (DataRequest, @escaping @Sendable (DataResponse<Value>) -> Void) -> Void

    init(request: DataRequest,
         responseHandler: @escaping @Sendable (DataRequest, @escaping @Sendable (DataResponse<Value>) -> Void) -> Void) {
        self.request = request
        self.responseHandler = responseHandler
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        let subscription = Inner(request: request, responseHandler: responseHandler, downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }

    private final class Inner<S: Subscriber>: Subscription where S.Input == DataResponse<Value>, S.Failure == Never {
        private var downstream: S?
        private let request: DataRequest
        private let responseHandler: @Sendable (DataRequest, @escaping @Sendable (DataResponse<Value>) -> Void) -> Void

        init(request: DataRequest,
             responseHandler: @escaping @Sendable (DataRequest, @escaping @Sendable (DataResponse<Value>) -> Void) -> Void,
             downstream: S) {
            self.request = request
            self.responseHandler = responseHandler
            self.downstream = downstream
        }

        func request(_ demand: Subscribers.Demand) {
            guard demand > 0 else { return }
            responseHandler(request) { [weak self] response in
                _ = self?.downstream?.receive(response)
                self?.downstream?.receive(completion: .finished)
            }
        }

        func cancel() { downstream = nil }
    }
}

// MARK: - DownloadResponsePublisher

/// Download 请求的 Combine Publisher，对齐 Alamofire 的 `DownloadResponsePublisher`。
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct DownloadResponsePublisher<Value: Sendable>: Publisher {
    public typealias Output = DownloadResponse<Value>
    public typealias Failure = Never

    private let request: DownloadRequest
    private let responseHandler: @Sendable (DownloadRequest, @escaping @Sendable (DownloadResponse<Value>) -> Void) -> Void

    init(request: DownloadRequest,
         responseHandler: @escaping @Sendable (DownloadRequest, @escaping @Sendable (DownloadResponse<Value>) -> Void) -> Void) {
        self.request = request
        self.responseHandler = responseHandler
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        let subscription = Inner(request: request, responseHandler: responseHandler, downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }

    private final class Inner<S: Subscriber>: Subscription where S.Input == DownloadResponse<Value>, S.Failure == Never {
        private var downstream: S?
        private let request: DownloadRequest
        private let responseHandler: @Sendable (DownloadRequest, @escaping @Sendable (DownloadResponse<Value>) -> Void) -> Void

        init(request: DownloadRequest,
             responseHandler: @escaping @Sendable (DownloadRequest, @escaping @Sendable (DownloadResponse<Value>) -> Void) -> Void,
             downstream: S) {
            self.request = request
            self.responseHandler = responseHandler
            self.downstream = downstream
        }

        func request(_ demand: Subscribers.Demand) {
            guard demand > 0 else { return }
            responseHandler(request) { [weak self] response in
                _ = self?.downstream?.receive(response)
                self?.downstream?.receive(completion: .finished)
            }
        }

        func cancel() { downstream = nil }
    }
}

// MARK: - DataRequest + Combine

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension DataRequest {

    /// 发布原始 Data 响应
    func publishData(queue: DispatchQueue? = nil) -> DataResponsePublisher<Data> {
        DataResponsePublisher(request: self) { req, handler in
            req.responseData(queue: queue, completionHandler: handler)
        }
    }

    /// 发布 String 响应
    func publishString(queue: DispatchQueue? = nil, encoding: String.Encoding = .utf8) -> DataResponsePublisher<String> {
        DataResponsePublisher(request: self) { req, handler in
            req.responseString(queue: queue, encoding: encoding, completionHandler: handler)
        }
    }

    /// 发布 Decodable 模型响应
    func publishDecodable<T: Decodable & Sendable>(
        type: T.Type = T.self,
        queue: DispatchQueue? = nil,
        decoder: JSONDecoder? = nil
    ) -> DataResponsePublisher<T> {
        DataResponsePublisher(request: self) { req, handler in
            req.responseDecodable(of: type, queue: queue, decoder: decoder, completionHandler: handler)
        }
    }

    /// 发布使用自定义序列化器的响应
    func publishResponse<Serializer: DataResponseSerializerProtocol>(
        using serializer: Serializer,
        queue: DispatchQueue? = nil
    ) -> DataResponsePublisher<Serializer.SerializedObject> {
        DataResponsePublisher(request: self) { req, handler in
            req.response(queue: queue, responseSerializer: serializer, completionHandler: handler)
        }
    }
}

// MARK: - DataResponsePublisher Convenience

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension DataResponsePublisher {

    /// 提取成功值，失败时抛出错误
    func value() -> AnyPublisher<Value, any Error> {
        self.setFailureType(to: (any Error).self)
            .tryMap { response in
                switch response.result {
                case .success(let value): return value
                case .failure(let error): throw error
                }
            }
            .eraseToAnyPublisher()
    }

    /// 提取 Result
    func result() -> AnyPublisher<Result<Value, any Error>, Never> {
        self.map(\.result).eraseToAnyPublisher()
    }
}

// MARK: - DownloadRequest + Combine

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension DownloadRequest {

    /// 发布下载 Data 响应
    func publishData(queue: DispatchQueue? = nil) -> DownloadResponsePublisher<Data> {
        DownloadResponsePublisher(request: self) { req, handler in
            req.responseData(queue: queue, completionHandler: handler)
        }
    }

    /// 发布下载 Decodable 模型响应
    func publishDecodable<T: Decodable & Sendable>(
        type: T.Type = T.self,
        queue: DispatchQueue? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) -> DownloadResponsePublisher<T> {
        DownloadResponsePublisher(request: self) { req, handler in
            req.responseDecodable(of: type, queue: queue, decoder: decoder, completionHandler: handler)
        }
    }

    /// 发布使用自定义序列化器的下载响应
    func publishResponse<Serializer: DownloadResponseSerializerProtocol>(
        using serializer: Serializer,
        queue: DispatchQueue? = nil
    ) -> DownloadResponsePublisher<Serializer.SerializedObject> {
        DownloadResponsePublisher(request: self) { req, handler in
            req.response(queue: queue, responseSerializer: serializer, completionHandler: handler)
        }
    }
}

// MARK: - DownloadResponsePublisher Convenience

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension DownloadResponsePublisher {

    /// 提取成功值，失败时抛出错误
    func value() -> AnyPublisher<Value, any Error> {
        self.setFailureType(to: (any Error).self)
            .tryMap { response in
                switch response.result {
                case .success(let value): return value
                case .failure(let error): throw error
                }
            }
            .eraseToAnyPublisher()
    }

    /// 提取 Result
    func result() -> AnyPublisher<Result<Value, any Error>, Never> {
        self.map(\.result).eraseToAnyPublisher()
    }
}

// MARK: - NetworkReachabilityManager + Combine

#if !os(watchOS)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension NetworkReachabilityManager {

    /// 发布网络可达性状态变化的 Publisher
    func publisher() -> AnyPublisher<NetworkReachabilityStatus, Never> {
        let subject = PassthroughSubject<NetworkReachabilityStatus, Never>()
        startListening { status in
            subject.send(status)
        }
        return subject
            .handleEvents(receiveCancel: { [weak self] in
                self?.stopListening()
            })
            .eraseToAnyPublisher()
    }
}
#endif

#endif // canImport(Combine)
