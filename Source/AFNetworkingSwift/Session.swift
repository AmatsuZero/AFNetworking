// Session.swift
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

// MARK: - SessionStorage Actor

/// 内部 Actor 封装 Session 的回调状态，替代 NSLock 保护 completionHandlers。
/// 使用 tombstone 模式解决 register/finalize 的 Task 执行顺序不确定性：
/// - 正常路径：register 先到 → 存入 handler → finalize 取出并执行
/// - 快速网络：finalize 先到 → 存入 tombstone → register 发现 tombstone 后直接执行 handler
actor SessionStorage {
    /// 请求完成回调映射
    private var completionHandlers: [String: @Sendable () -> Void] = [:]
    /// Tombstone 集合：finalize 先于 register 到达时留下标记
    private var earlyFinalized: Set<String> = []

    /// 注册完成回调。返回 `false` 表示 handler 应由调用者直接执行（已 finalize 或已 finished）。
    func registerIfNotFinished(request: Request, handler: @escaping @Sendable () -> Void) -> Bool {
        let id = request.id

        // Case 1: finalize 已先到 — 消费 tombstone，调用者直接执行 handler
        if earlyFinalized.remove(id) != nil {
            return false
        }
        // Case 2: 请求已完成
        if request.context.state == .finished {
            return false
        }
        // 正常路径：存储 handler 等待 finalize 取出
        completionHandlers[id] = handler
        return true
    }

    /// 取出并执行完成回调。若 register 尚未到达，留下 tombstone。
    func finalize(identifier: String) -> (@Sendable () -> Void)? {
        if let handler = completionHandlers.removeValue(forKey: identifier) {
            return handler // 正常路径：register 先到
        }
        // register 尚未到达 — 留下 tombstone
        earlyFinalized.insert(identifier)
        return nil
    }

    /// 取消请求时清理状态
    func cancel(identifier: String) {
        completionHandlers.removeValue(forKey: identifier)
        earlyFinalized.remove(identifier)
    }
}

/// Session 是 Swift 包装层的核心入口，对齐 Alamofire 的 `Session`。
/// 底层复用 `AFHTTPSessionManager` 的执行能力。
public class Session: @unchecked Sendable {

    // MARK: - 默认实例

    /// 默认 Session 实例
    public static let `default` = Session()

    // MARK: - 属性

    /// 底层 AFHTTPSessionManager
    public let sessionManager: AFHTTPSessionManager

    /// Session 级别的拦截器
    public let interceptor: (any RequestIntercepting)?

    /// Combine-based 事件监控器
    public let eventMonitor: EventMonitor

    /// Session 级别的服务器信任管理器
    public let serverTrustManager: ServerTrustManager?

    /// 缓存响应处理器
    public let cachedResponseHandler: (any CachedResponseHandler)?

    /// 重定向处理器
    public let redirectHandler: (any RedirectHandler)?

    /// 内部调度队列 — 协调 ObjC `AFHTTPSessionManager` API 调用，与 Actor 状态保护正交
    private let rootQueue: DispatchQueue

    /// 内部 Actor 封装回调状态
    private let storage = SessionStorage()

    /// 活跃请求集合 — 同步访问保证请求不会被提前释放
    private var activeRequests: [String: Request] = [:]
    private let requestLock = NSLock()

    // MARK: - 初始化

    /// 创建 Session
    public init(configuration: URLSessionConfiguration = .default,
                interceptor: (any RequestIntercepting)? = nil,
                serverTrustManager: ServerTrustManager? = nil,
                cachedResponseHandler: (any CachedResponseHandler)? = nil,
                redirectHandler: (any RedirectHandler)? = nil,
                eventMonitor: EventMonitor = EventMonitor()) {
        self.rootQueue = DispatchQueue(label: "com.alamofire.afnetworking.session.\(UUID().uuidString)")
        self.sessionManager = AFHTTPSessionManager(sessionConfiguration: configuration)
        self.sessionManager.responseSerializer = AFHTTPResponseSerializer()
        self.sessionManager.completionQueue = DispatchQueue(label: "com.alamofire.afnetworking.session.completion.\(UUID().uuidString)")
        self.interceptor = interceptor
        self.serverTrustManager = serverTrustManager
        self.cachedResponseHandler = cachedResponseHandler
        self.redirectHandler = redirectHandler
        self.eventMonitor = eventMonitor
        setupSessionManagerBlocks()
    }

    /// 使用现有 AFHTTPSessionManager 创建 Session
    public init(sessionManager: AFHTTPSessionManager,
                interceptor: (any RequestIntercepting)? = nil,
                serverTrustManager: ServerTrustManager? = nil,
                cachedResponseHandler: (any CachedResponseHandler)? = nil,
                redirectHandler: (any RedirectHandler)? = nil,
                eventMonitor: EventMonitor = EventMonitor()) {
        self.rootQueue = DispatchQueue(label: "com.alamofire.afnetworking.session.\(UUID().uuidString)")
        self.sessionManager = sessionManager
        self.interceptor = interceptor
        self.serverTrustManager = serverTrustManager
        self.cachedResponseHandler = cachedResponseHandler
        self.redirectHandler = redirectHandler
        self.eventMonitor = eventMonitor
        setupSessionManagerBlocks()
    }

    private func setupSessionManagerBlocks() {
        if let handler = cachedResponseHandler {
            sessionManager.setDataTaskWillCacheResponseBlock { _, task, response in
                return handler.dataTask(task, willCacheResponse: response) ?? response
            }
        }
        if let handler = redirectHandler {
            sessionManager.setTaskWillPerformHTTPRedirectionBlock { _, task, response, request in
                guard let httpResponse = response as? HTTPURLResponse else { return request }
                return handler.task(task, willBeRedirectedTo: request, for: httpResponse)
            }
        }
    }

    // MARK: - 请求创建辅助

    /// 创建并配置 RequestDescriptor + RequestContext
    private func makeContext(urlString: String,
                             method: HTTPMethod,
                             parameters: [String: Any]?,
                             encoding: ParameterEncoding,
                             headers: HTTPHeaders?,
                             interceptor: (any RequestIntercepting)?) -> RequestContext {
        let descriptor = RequestDescriptor(
            urlString: urlString,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers
        )
        descriptor.interceptor = interceptor
        return RequestContext(descriptor: descriptor)
    }

    // MARK: - Data Request

    @discardableResult
    public func request(_ convertible: String,
                        method: HTTPMethod = .GET,
                        parameters: [String: Any]? = nil,
                        encoding: ParameterEncoding = .auto,
                        headers: HTTPHeaders? = nil,
                        interceptor: (any RequestIntercepting)? = nil) -> DataRequest {
        let context = makeContext(urlString: convertible, method: method, parameters: parameters,
                                 encoding: encoding, headers: headers, interceptor: interceptor)
        let request = DataRequest(context: context, session: self)

        eventMonitor.send(.created(context))
        trackRequest(request) // 同步跟踪，保证请求不会被提前释放
        performDataRequest(request)

        return request
    }

    // MARK: - Download Request

    @discardableResult
    public func download(_ convertible: String,
                         method: HTTPMethod = .GET,
                         parameters: [String: Any]? = nil,
                         encoding: ParameterEncoding = .auto,
                         headers: HTTPHeaders? = nil,
                         interceptor: (any RequestIntercepting)? = nil,
                         to destination: DownloadDestination? = nil) -> DownloadRequest {
        let context = makeContext(urlString: convertible, method: method, parameters: parameters,
                                 encoding: encoding, headers: headers, interceptor: interceptor)
        let request = DownloadRequest(context: context, session: self, destination: destination)

        eventMonitor.send(.created(context))
        trackRequest(request) // 同步跟踪，保证请求不会被提前释放
        performDownloadRequest(request)

        return request
    }

    /// 断点续传下载（P1-3）
    @discardableResult
    public func download(resumingWith resumeData: Data,
                         interceptor: (any RequestIntercepting)? = nil,
                         to destination: DownloadDestination? = nil) -> DownloadRequest {
        let descriptor = RequestDescriptor(urlString: "", method: .GET, parameters: nil,
                                           encoding: .auto, headers: nil)
        descriptor.interceptor = interceptor
        let context = RequestContext(descriptor: descriptor)
        let request = DownloadRequest(context: context, session: self, destination: destination)

        eventMonitor.send(.created(context))
        trackRequest(request)
        performResumedDownloadRequest(request, resumeData: resumeData)

        return request
    }

    // MARK: - Upload Request

    /// 上传 Data（P1-1）
    @discardableResult
    public func upload(_ data: Data,
                       to urlString: String,
                       method: HTTPMethod = .POST,
                       headers: HTTPHeaders? = nil,
                       interceptor: (any RequestIntercepting)? = nil) -> UploadRequest {
        let context = makeContext(urlString: urlString, method: method, parameters: nil,
                                 encoding: .auto, headers: headers, interceptor: interceptor)
        let request = UploadRequest(uploadable: .data(data), context: context, session: self)

        eventMonitor.send(.created(context))
        trackRequest(request)
        performUploadRequest(request)

        return request
    }

    /// 上传本地文件（P1-1）
    @discardableResult
    public func upload(fileAt fileURL: URL,
                       to urlString: String,
                       method: HTTPMethod = .POST,
                       headers: HTTPHeaders? = nil,
                       interceptor: (any RequestIntercepting)? = nil) -> UploadRequest {
        let context = makeContext(urlString: urlString, method: method, parameters: nil,
                                 encoding: .auto, headers: headers, interceptor: interceptor)
        let request = UploadRequest(uploadable: .file(fileURL), context: context, session: self)

        eventMonitor.send(.created(context))
        trackRequest(request)
        performUploadRequest(request)

        return request
    }

    /// 上传输入流（P1-1）
    @discardableResult
    public func upload(_ stream: InputStream,
                       to urlString: String,
                       method: HTTPMethod = .POST,
                       headers: HTTPHeaders? = nil,
                       interceptor: (any RequestIntercepting)? = nil) -> UploadRequest {
        let context = makeContext(urlString: urlString, method: method, parameters: nil,
                                 encoding: .auto, headers: headers, interceptor: interceptor)
        let request = UploadRequest(uploadable: .stream(stream), context: context, session: self)

        eventMonitor.send(.created(context))
        trackRequest(request)
        performUploadRequest(request)

        return request
    }

    /// Multipart Form Data 上传（P2-1 + P1-1）
    @discardableResult
    public func upload(multipartFormData formDataBuilder: @escaping (MultipartFormData) -> Void,
                       to urlString: String,
                       method: HTTPMethod = .POST,
                       headers: HTTPHeaders? = nil,
                       interceptor: (any RequestIntercepting)? = nil) -> UploadRequest {
        let context = makeContext(urlString: urlString, method: method, parameters: nil,
                                 encoding: .auto, headers: headers, interceptor: interceptor)
        let request = UploadRequest(uploadable: .multipartFormData(formDataBuilder),
                                    context: context, session: self)

        eventMonitor.send(.created(context))
        trackRequest(request)
        performUploadRequest(request)

        return request
    }

    // MARK: - 内部执行

    private func performDataRequest(_ request: DataRequest) {
        let context = request.context
        let descriptor = context.descriptor

        rootQueue.async { [weak self] in
            guard let self = self else { return }

            let headerDict = descriptor.headers?.dictionary ?? [:]

            let task = self.sessionManager.dataTask(
                withHTTPMethod: descriptor.method.rawValue,
                urlString: descriptor.urlString,
                parameters: descriptor.parameters as? [String: Any],
                headers: headerDict,
                uploadProgress: nil,
                downloadProgress: { request.downloadProgressHandler?($0) },
                success: { [weak self] (task: URLSessionDataTask, responseObject: Any?) in
                    guard let self = self else { return }
                    context.response = task.response as? HTTPURLResponse
                    context.serializedObject = responseObject
                    if let data = responseObject as? Data {
                        context.mutableData = NSMutableData(data: data)
                    }
                    context.state = .finished
                    self.eventMonitor.send(.finished(context))
                    self.finalizeRequest(identifier: context.identifier)
                },
                failure: { [weak self] (task: URLSessionDataTask?, error: Error) in
                    guard let self = self else { return }
                    context.response = task?.response as? HTTPURLResponse
                    context.error = error
                    context.state = .finished
                    self.eventMonitor.send(.finished(context))
                    self.finalizeRequest(identifier: context.identifier)
                }
            )

            context.task = task
            context.state = .resumed
            task?.resume()

            self.eventMonitor.send(.resumed(context))
        }
    }

    private func performDownloadRequest(_ request: DownloadRequest) {
        let context = request.context
        let descriptor = context.descriptor

        rootQueue.async { [weak self] in
            guard let self = self else { return }

            guard let url = URL(string: descriptor.urlString) else {
                context.error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)
                context.state = .finished
                self.eventMonitor.send(.finished(context))
                return
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = descriptor.method.rawValue

            if let headers = descriptor.headers {
                for (name, value) in headers.dictionary {
                    urlRequest.setValue(value, forHTTPHeaderField: name)
                }
            }

            let task = self.sessionManager.downloadTask(
                with: urlRequest,
                progress: { request.downloadProgressHandler?($0) },
                destination: { (targetPath: URL, response: URLResponse) -> URL in
                    if let dest = request.destination,
                       let httpResponse = response as? HTTPURLResponse {
                        let (url, options) = dest.handler(targetPath, httpResponse)
                        if options.contains(.createIntermediateDirectories) {
                            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                                     withIntermediateDirectories: true)
                        }
                        if options.contains(.removePreviousFile) {
                            try? FileManager.default.removeItem(at: url)
                        }
                        return url
                    }
                    return targetPath
                },
                completionHandler: { [weak self] (response: URLResponse, fileURL: URL?, error: Error?) in
                    guard let self = self else { return }
                    context.response = response as? HTTPURLResponse
                    context.fileURL = fileURL
                    context.error = error
                    context.state = .finished
                    self.eventMonitor.send(.finished(context))
                    self.finalizeRequest(identifier: context.identifier)
                }
            )

            context.task = task
            context.state = .resumed
            task.resume()

            self.eventMonitor.send(.resumed(context))
        }
    }

    // MARK: - 内部执行（上传）

    private func buildURLRequest(from descriptor: RequestDescriptor) -> URLRequest? {
        guard let url = URL(string: descriptor.urlString) else { return nil }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = descriptor.method.rawValue
        if let headers = descriptor.headers {
            for (name, value) in headers.dictionary {
                urlRequest.setValue(value, forHTTPHeaderField: name)
            }
        }
        return urlRequest
    }

    private func performUploadRequest(_ request: UploadRequest) {
        let context = request.context
        let descriptor = context.descriptor

        rootQueue.async { [weak self] in
            guard let self else { return }

            let progressBlock = request.uploadProgressHandler

            let completionHandler: (URLResponse, Any?, Error?) -> Void = { [weak self] response, responseObject, error in
                guard let self else { return }
                context.response = response as? HTTPURLResponse
                if let data = responseObject as? Data {
                    context.mutableData = NSMutableData(data: data)
                }
                context.error = error
                context.state = .finished
                self.eventMonitor.send(.finished(context))
                self.finalizeRequest(identifier: context.identifier)
            }

            switch request.uploadable {
            case .data(let data):
                guard let urlRequest = self.buildURLRequest(from: descriptor) else {
                    context.error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL)
                    context.state = .finished
                    self.eventMonitor.send(.finished(context))
                    return
                }
                let task = self.sessionManager.uploadTask(with: urlRequest, from: data,
                                                          progress: { progressBlock?($0) },
                                                          completionHandler: completionHandler)
                context.task = task
                context.state = .resumed
                task.resume()

            case .file(let fileURL):
                guard let urlRequest = self.buildURLRequest(from: descriptor) else {
                    context.error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL)
                    context.state = .finished
                    self.eventMonitor.send(.finished(context))
                    return
                }
                let task = self.sessionManager.uploadTask(with: urlRequest, fromFile: fileURL,
                                                          progress: { progressBlock?($0) },
                                                          completionHandler: completionHandler)
                context.task = task
                context.state = .resumed
                task.resume()

            case .stream:
                guard let urlRequest = self.buildURLRequest(from: descriptor) else {
                    context.error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL)
                    context.state = .finished
                    self.eventMonitor.send(.finished(context))
                    return
                }
                let task = self.sessionManager.uploadTask(withStreamedRequest: urlRequest,
                                                          progress: { progressBlock?($0) },
                                                          completionHandler: completionHandler)
                context.task = task
                context.state = .resumed
                task.resume()

            case .multipartFormData(let formDataBuilder):
                let headerDict = descriptor.headers?.dictionary ?? [:]
                let task = self.sessionManager.post(
                    descriptor.urlString,
                    parameters: nil,
                    headers: headerDict,
                    constructingBodyWith: { objcFormData in
                        let swiftFormData = MultipartFormData(underlying: objcFormData)
                        formDataBuilder(swiftFormData)
                    },
                    progress: { progressBlock?($0) },
                    success: { dataTask, responseObject in
                        completionHandler(dataTask.response!, responseObject, nil)
                    },
                    failure: { dataTask, error in
                        completionHandler(dataTask?.response ?? URLResponse(), nil, error)
                    }
                )
                if let task {
                    context.task = task
                    context.state = .resumed
                }
            }

            self.eventMonitor.send(.resumed(context))
        }
    }

    // MARK: - 内部执行（断点续传）

    private func performResumedDownloadRequest(_ request: DownloadRequest, resumeData: Data) {
        let context = request.context

        rootQueue.async { [weak self] in
            guard let self else { return }

            let task = self.sessionManager.downloadTask(
                withResumeData: resumeData,
                progress: nil,
                destination: { (targetPath: URL, response: URLResponse) -> URL in
                    if let dest = request.destination,
                       let httpResponse = response as? HTTPURLResponse {
                        let (url, options) = dest.handler(targetPath, httpResponse)
                        if options.contains(.createIntermediateDirectories) {
                            try? FileManager.default.createDirectory(
                                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                        }
                        if options.contains(.removePreviousFile) {
                            try? FileManager.default.removeItem(at: url)
                        }
                        return url
                    }
                    return targetPath
                },
                completionHandler: { [weak self] response, fileURL, error in
                    guard let self else { return }
                    context.response = response as? HTTPURLResponse
                    context.fileURL = fileURL
                    context.error = error
                    context.state = .finished
                    self.eventMonitor.send(.finished(context))
                    self.finalizeRequest(identifier: context.identifier)
                }
            )

            context.task = task
            context.state = .resumed
            task.resume()
            self.eventMonitor.send(.resumed(context))
        }
    }

    // MARK: - 请求完成处理（Actor 桥接）

    /// 从 Actor 中取出 handler 并调用，同步移除活跃请求
    private func finalizeRequest(identifier: String) {
        requestLock.lock()
        activeRequests.removeValue(forKey: identifier)
        requestLock.unlock()

        // Actor 中取出并执行回调
        Task.detached {
            let handler = await self.storage.finalize(identifier: identifier)
            handler?()
        }
    }

    // MARK: - 回调注册（Actor 桥接）

    internal func registerCompletion(for request: Request, handler: @escaping @Sendable () -> Void) {
        Task.detached {
            let registered = await self.storage.registerIfNotFinished(request: request, handler: handler)
            if !registered {
                handler()
            }
        }
    }

    // 保留向后兼容
    internal func registerDownloadCompletion(for request: DownloadRequest, handler: @escaping @Sendable () -> Void) {
        registerCompletion(for: request, handler: handler)
    }

    // MARK: - 请求跟踪（同步，保证请求生命周期）

    private func trackRequest(_ request: Request) {
        requestLock.lock()
        activeRequests[request.id] = request
        requestLock.unlock()
    }

}
