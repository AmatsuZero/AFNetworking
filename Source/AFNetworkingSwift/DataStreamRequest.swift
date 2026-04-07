// DataStreamRequest.swift
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
import os.lock
#if SWIFT_PACKAGE
import AFNetworking
#endif

/// 流式数据请求类型，对齐 Alamofire 的 `DataStreamRequest`。
/// 与 `DataRequest` 不同，本类在每次收到数据块时立即通过 handler 回调，
/// 而非将所有数据累积在内存中。适用于 SSE、大文件流式处理、实时数据流等场景。
///
/// 底层使用 `URLSessionDataTask`，通过 OC 层 `AFURLSessionManager` 的
/// `URLSession:dataTask:didReceiveData:` 代理方法接收数据块。
public final class DataStreamRequest: Request, @unchecked Sendable {

    // MARK: - 公共类型

    /// 流式 handler 闭包类型。
    /// - Parameter stream: 包含当前事件和取消令牌的流对象。
    public typealias Handler<Success: Sendable, Failure: Error> = @Sendable (Stream<Success, Failure>) throws -> Void

    /// 流式事件包装，包含当前事件和取消令牌。
    /// 对齐 Alamofire 的 `DataStreamRequest.Stream`。
    public struct Stream<Success: Sendable, Failure: Error>: Sendable where Failure: Sendable {
        /// 当前流事件
        public let event: Event<Success, Failure>
        /// 取消令牌，可在 handler 内取消请求
        public let token: CancellationToken

        /// 便捷方法：取消底层请求
        public func cancel() {
            token.cancel()
        }
    }

    /// 流式事件枚举。
    /// 对齐 Alamofire 的 `DataStreamRequest.Event`。
    public enum Event<Success: Sendable, Failure: Error>: Sendable where Failure: Sendable {
        /// 收到一个数据块（成功或失败）
        case stream(Result<Success, Failure>)
        /// 流已完成（正常结束、取消或错误）
        case complete(Completion)
    }

    /// 流完成信息。
    /// 对齐 Alamofire 的 `DataStreamRequest.Completion`。
    public struct Completion: Sendable {
        /// 最后发出的 URLRequest
        public let request: URLRequest?
        /// 最后收到的 HTTPURLResponse
        public let response: HTTPURLResponse?
        /// 任务性能指标
        public let metrics: URLSessionTaskMetrics?
        /// 错误（如有）
        public let error: (any Error)?
    }

    /// 取消令牌，允许在流回调中取消请求。
    /// 对齐 Alamofire 的 `DataStreamRequest.CancellationToken`。
    public struct CancellationToken: Sendable {
        weak var request: DataStreamRequest?

        init(_ request: DataStreamRequest) {
            self.request = request
        }

        /// 取消底层请求
        public func cancel() {
            request?.cancel()
        }
    }

    /// HTTP 响应处置方式，控制流是否继续。
    /// 对齐 Alamofire 的 `Request.ResponseDisposition`。
    public enum ResponseDisposition: Sendable {
        /// 允许流继续
        case allow
        /// 取消流
        case cancel
    }

    // MARK: - 公共属性

    /// 是否在流处理器抛出错误时自动取消请求
    public let automaticallyCancelOnStreamError: Bool

    /// 序列化专用队列，避免在用户队列（通常是 main）执行 CPU 密集操作
    let serializationQueue: DispatchQueue

    // MARK: - 内部状态

    /// 流式请求的可变状态，使用 os_unfair_lock 保护（与 RequestContext 一致的模式）。
    private struct StreamMutableState {
        /// 已注册的流处理器列表，每次收到数据块时调用
        var streams: [@Sendable (_ data: Data) -> Void] = []
        /// 当前正在执行的流处理器数量
        var numberOfExecutingStreams = 0
        /// 等待所有流处理器完成后执行的 completion 事件
        var enqueuedCompletionEvents: [@Sendable () -> Void] = []
        /// HTTP 响应头处理器（可选）
        var httpResponseHandler: (queue: DispatchQueue,
                                  handler: @Sendable (_ response: HTTPURLResponse,
                                                      _ completionHandler: @escaping @Sendable (ResponseDisposition) -> Void) -> Void)?
        /// 用于 asInputStream 的输出流
        var outputStream: OutputStream?
    }

    /// 锁保护的可变状态
    private var streamMutableState = StreamMutableState()
    private var _streamLock = os_unfair_lock()

    /// 线程安全地访问 streamMutableState
    private func withStreamLock<T>(_ body: (inout StreamMutableState) -> T) -> T {
        os_unfair_lock_lock(&_streamLock)
        defer { os_unfair_lock_unlock(&_streamLock) }
        return body(&streamMutableState)
    }

    // MARK: - 初始化

    init(context: RequestContext,
         session: Session,
         automaticallyCancelOnStreamError: Bool,
         serializationQueue: DispatchQueue,
         completionQueue: DispatchQueue = .main) {
        self.automaticallyCancelOnStreamError = automaticallyCancelOnStreamError
        self.serializationQueue = serializationQueue
        super.init(context: context, session: session, completionQueue: completionQueue)
    }

    // MARK: - 数据接收（由 Session 层调用）

    /// 收到一个数据块时调用。将数据分发给所有已注册的流处理器。
    /// - Parameter data: 从服务器接收到的数据块。
    func didReceive(data: Data) {
        let (streams, outputStream): ([@Sendable (_ data: Data) -> Void], OutputStream?) = withStreamLock { state in
            state.numberOfExecutingStreams += state.streams.count
            return (state.streams, state.outputStream)
        }

        // 写入 OutputStream（供 asInputStream 消费者读取）
        if let outputStream {
            data.withUnsafeBytes { rawBuffer in
                guard let pointer = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
                outputStream.write(pointer, maxLength: data.count)
            }
        }

        for stream in streams {
            stream(data)
        }
    }

    /// 收到 HTTP 响应头时调用（异步通知模式，不阻塞 URLSession delegate）。
    /// 先返回 .allow 让数据继续流入，handler 若选择 .cancel 则异步取消请求。
    func notifyHTTPResponse(_ response: HTTPURLResponse) {
        // 保存响应头到 context，供 validate 使用
        context.response = response

        let handler: (queue: DispatchQueue,
                      handler: @Sendable (HTTPURLResponse,
                                          @escaping @Sendable (ResponseDisposition) -> Void) -> Void)? = withStreamLock { state in
            state.httpResponseHandler
        }

        guard let handler else { return }

        handler.queue.async {
            handler.handler(response) { [weak self] disposition in
                if case .cancel = disposition {
                    self?.cancel()
                }
            }
        }
    }

    // MARK: - 流完成处理

    /// 流结束时调用（task 完成后），由 Session 层触发。
    func streamDidComplete() {
        // 关闭 OutputStream
        withStreamLock { state in
            state.outputStream?.close()
            state.outputStream = nil
        }

        let completionEvents: [@Sendable () -> Void] = withStreamLock { state in
            let events = state.enqueuedCompletionEvents
            state.enqueuedCompletionEvents.removeAll()
            return events
        }

        for event in completionEvents {
            event()
        }
    }

    /// 注册 stream completion 回调，在所有数据块处理完毕后执行。
    private func appendStreamCompletion<Success: Sendable, Failure: Error>(
        on queue: DispatchQueue,
        stream: @escaping Handler<Success, Failure>
    ) where Failure: Sendable {
        let token = CancellationToken(self)
        // 延迟构建 Completion，确保在 streamDidComplete 时才读取 context 状态
        let event: @Sendable () -> Void = { [weak self] in
            guard let self else { return }
            let completion = Completion(
                request: self.context.currentRequest,
                response: self.context.response,
                metrics: self.metricsIfAvailable,
                error: self.performValidation() ?? self.context.error
            )
            queue.async {
                do {
                    try stream(Stream(event: .complete(completion), token: token))
                } catch {
                    // completion handler 错误不再静默丢弃
                    self.context.error = self.context.error ?? error
                }
            }
        }

        withStreamLock { state in
            state.enqueuedCompletionEvents.append(event)
        }
    }

    /// 流处理器执行完毕后调用，递减计数器并检查是否可以触发 completion。
    private func updateAndCompleteIfPossible() {
        let completionEvents: [@Sendable () -> Void] = withStreamLock { state in
            state.numberOfExecutingStreams -= 1
            guard state.numberOfExecutingStreams == 0,
                  !state.enqueuedCompletionEvents.isEmpty else {
                return []
            }
            let events = state.enqueuedCompletionEvents
            state.enqueuedCompletionEvents.removeAll()
            return events
        }

        for event in completionEvents {
            event()
        }
    }

    // MARK: - InputStream 支持

    /// 创建一个与流式数据绑定的 InputStream。
    /// 对齐 Alamofire 的 `DataStreamRequest.asInputStream(bufferSize:)`。
    /// - Parameter bufferSize: 内部缓冲区大小，默认 1024 字节。
    /// - Returns: 可读取流式数据的 InputStream，如果已调用过则返回 nil。
    public func asInputStream(bufferSize: Int = 1024) -> InputStream? {
        var inputStream: InputStream?
        var outputStream: OutputStream?

        Foundation.Stream.getBoundStreams(withBufferSize: bufferSize, inputStream: &inputStream, outputStream: &outputStream)

        guard let input = inputStream, let output = outputStream else { return nil }

        let stored = withStreamLock { state -> Bool in
            guard state.outputStream == nil else { return false }
            output.open()
            state.outputStream = output
            return true
        }

        guard stored else { return nil }
        return input
    }

    // MARK: - 错误捕获

    /// 捕获 handler 抛出的错误，存入 context 并在需要时取消请求。
    private func captureHandlerError(_ error: Error, automaticallyCancel: Bool) {
        context.error = context.error ?? error
        if automaticallyCancel {
            cancel()
        }
    }

    // MARK: - 公共 API：HTTP 响应处理

    /// 注册 HTTP 响应头回调，支持 disposition 控制（允许或取消流）。
    /// 对齐 Alamofire 的 `DataStreamRequest.onHTTPResponse(on:perform:)`。
    /// - Parameters:
    ///   - queue: 回调执行队列，默认 `.main`。
    ///   - handler: 接收 HTTPURLResponse 和 disposition 回调的闭包。
    @discardableResult
    public func onHTTPResponse(
        on queue: DispatchQueue = .main,
        perform handler: @escaping @Sendable (_ response: HTTPURLResponse,
                                              _ completionHandler: @escaping @Sendable (ResponseDisposition) -> Void) -> Void
    ) -> Self {
        withStreamLock { state in
            state.httpResponseHandler = (queue, handler)
        }
        return self
    }

    /// 注册简单的 HTTP 响应头回调（自动 allow）。
    /// 对齐 Alamofire 的 `DataStreamRequest.onHTTPResponse(on:perform:)` 简化版。
    /// - Parameters:
    ///   - queue: 回调执行队列，默认 `.main`。
    ///   - handler: 接收 HTTPURLResponse 的闭包。
    @discardableResult
    public func onHTTPResponse(
        on queue: DispatchQueue = .main,
        perform handler: @escaping @Sendable (HTTPURLResponse) -> Void
    ) -> Self {
        onHTTPResponse(on: queue) { response, completionHandler in
            handler(response)
            completionHandler(.allow)
        }
    }

    // MARK: - 公共 API：流式响应方法

    /// 接收原始 Data 流。每收到一个数据块回调一次。
    /// 对齐 Alamofire 的 `DataStreamRequest.responseStream(on:stream:)`。
    /// - Parameters:
    ///   - queue: 回调执行队列，默认 `.main`。
    ///   - stream: 流式 handler，接收 `Stream<Data, Never>`。
    @discardableResult
    public func responseStream(
        on queue: DispatchQueue = .main,
        stream: @escaping Handler<Data, Never>
    ) -> Self {
        let token = CancellationToken(self)
        let automaticallyCancel = automaticallyCancelOnStreamError
        let streamClosure: @Sendable (Data) -> Void = { [weak self] data in
            queue.async {
                do {
                    try stream(Stream(event: .stream(.success(data)), token: token))
                } catch {
                    self?.captureHandlerError(error, automaticallyCancel: automaticallyCancel)
                }
                self?.updateAndCompleteIfPossible()
            }
        }

        withStreamLock { state in
            state.streams.append(streamClosure)
        }

        appendStreamCompletion(on: queue, stream: stream)
        return self
    }

    /// 使用自定义序列化器处理流式数据。每收到一个数据块序列化并回调一次。
    /// 对齐 Alamofire 的 `DataStreamRequest.responseStream(using:on:stream:)`。
    /// - Parameters:
    ///   - serializer: 流式数据序列化器。
    ///   - queue: 回调执行队列，默认 `.main`。
    ///   - stream: 流式 handler。
    @discardableResult
    public func responseStream<Serializer: DataStreamSerializer>(
        using serializer: Serializer,
        on queue: DispatchQueue = .main,
        stream: @escaping Handler<Serializer.SerializedObject, Error>
    ) -> Self {
        let token = CancellationToken(self)
        let automaticallyCancel = automaticallyCancelOnStreamError
        let serQueue = serializationQueue
        let streamClosure: @Sendable (Data) -> Void = { [weak self] data in
            serQueue.async {
                do {
                    let value = try serializer.serialize(data)
                    queue.async {
                        do {
                            try stream(Stream(event: .stream(.success(value)), token: token))
                        } catch {
                            self?.captureHandlerError(error, automaticallyCancel: automaticallyCancel)
                        }
                        self?.updateAndCompleteIfPossible()
                    }
                } catch {
                    queue.async {
                        do {
                            try stream(Stream(event: .stream(.failure(error)), token: token))
                        } catch {
                            self?.captureHandlerError(error, automaticallyCancel: automaticallyCancel)
                        }
                        self?.updateAndCompleteIfPossible()
                    }
                }
            }
        }

        withStreamLock { state in
            state.streams.append(streamClosure)
        }

        appendStreamCompletion(on: queue, stream: stream)
        return self
    }

    /// 接收 UTF8 String 流。每收到一个数据块解码并回调一次。
    /// 对齐 Alamofire 的 `DataStreamRequest.responseStreamString(on:stream:)`。
    /// - Parameters:
    ///   - queue: 回调执行队列，默认 `.main`。
    ///   - stream: 流式 handler，接收 `Stream<String, Never>`。
    @discardableResult
    public func responseStreamString(
        on queue: DispatchQueue = .main,
        stream: @escaping Handler<String, Never>
    ) -> Self {
        let token = CancellationToken(self)
        let automaticallyCancel = automaticallyCancelOnStreamError
        let streamClosure: @Sendable (Data) -> Void = { [weak self] data in
            queue.async {
                let string = String(decoding: data, as: UTF8.self)
                do {
                    try stream(Stream(event: .stream(.success(string)), token: token))
                } catch {
                    self?.captureHandlerError(error, automaticallyCancel: automaticallyCancel)
                }
                self?.updateAndCompleteIfPossible()
            }
        }

        withStreamLock { state in
            state.streams.append(streamClosure)
        }

        appendStreamCompletion(on: queue, stream: stream)
        return self
    }

    /// 接收 Decodable 对象流。每收到一个数据块 JSON 解码并回调一次。
    /// 对齐 Alamofire 的 `DataStreamRequest.responseStreamDecodable(of:on:using:preprocessor:stream:)`。
    /// - Parameters:
    ///   - type: 目标 Decodable 类型。
    ///   - queue: 回调执行队列，默认 `.main`。
    ///   - decoder: 数据解码器，默认 JSONDecoder。
    ///   - preprocessor: 数据预处理器，默认直通。
    ///   - stream: 流式 handler。
    @discardableResult
    public func responseStreamDecodable<T: Decodable & Sendable>(
        of type: T.Type = T.self,
        on queue: DispatchQueue = .main,
        using decoder: any DataDecoder = JSONDecoder(),
        preprocessor: any DataPreprocessor = PassthroughPreprocessor(),
        stream: @escaping Handler<T, Error>
    ) -> Self {
        responseStream(
            using: DecodableStreamSerializer<T>(decoder: decoder, preprocessor: preprocessor),
            on: queue,
            stream: stream
        )
    }
}

// MARK: - Stream 便利属性

extension DataStreamRequest.Stream {
    /// 提取 stream 事件中的 Result（如果当前事件是 `.stream`）。
    public var result: Result<Success, Failure>? {
        guard case let .stream(result) = event else { return nil }
        return result
    }

    /// 提取 stream 事件中的成功值。
    public var value: Success? {
        guard case let .success(value) = result else { return nil }
        return value
    }

    /// 提取 stream 事件中的失败错误。
    public var error: Failure? {
        guard case let .failure(error) = result else { return nil }
        return error
    }

    /// 提取 complete 事件中的完成信息。
    public var completion: DataStreamRequest.Completion? {
        guard case let .complete(completion) = event else { return nil }
        return completion
    }
}
