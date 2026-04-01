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
import AFSwiftSupport
#endif

// MARK: - Sendable conformance for ObjC types used across concurrency boundaries

extension RequestContext: @unchecked Sendable {}
extension RequestDescriptor: @unchecked Sendable {}

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

    /// Session 级别的事件监控器
    public let eventMonitors: [any EventMonitoring]

    /// Session 级别的服务器信任管理器
    public let serverTrustManager: ServerTrustManager?

    /// 内部调度队列
    private let rootQueue: DispatchQueue

    /// 请求完成回调映射（统一 data/download）
    private var completionHandlers: [String: () -> Void] = [:]
    private let lock = NSLock()

    /// 活跃请求集合
    private var activeRequests: [String: Request] = [:]

    // MARK: - 初始化

    /// 创建 Session
    public init(configuration: URLSessionConfiguration = .default,
                interceptor: (any RequestIntercepting)? = nil,
                serverTrustManager: ServerTrustManager? = nil,
                eventMonitors: [any EventMonitoring] = []) {
        self.rootQueue = DispatchQueue(label: "com.alamofire.afnetworking.session.\(UUID().uuidString)")
        self.sessionManager = AFHTTPSessionManager(sessionConfiguration: configuration)
        self.sessionManager.responseSerializer = AFHTTPResponseSerializer()
        self.sessionManager.completionQueue = DispatchQueue(label: "com.alamofire.afnetworking.session.completion.\(UUID().uuidString)")
        self.interceptor = interceptor
        self.serverTrustManager = serverTrustManager
        self.eventMonitors = eventMonitors
    }

    /// 使用现有 AFHTTPSessionManager 创建 Session
    public init(sessionManager: AFHTTPSessionManager,
                interceptor: (any RequestIntercepting)? = nil,
                serverTrustManager: ServerTrustManager? = nil,
                eventMonitors: [any EventMonitoring] = []) {
        self.rootQueue = DispatchQueue(label: "com.alamofire.afnetworking.session.\(UUID().uuidString)")
        self.sessionManager = sessionManager
        self.interceptor = interceptor
        self.serverTrustManager = serverTrustManager
        self.eventMonitors = eventMonitors
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

        notifyMonitors { $0.requestDidCreate?(context) }
        trackRequest(request)
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

        notifyMonitors { $0.requestDidCreate?(context) }
        trackRequest(request)
        performDownloadRequest(request)

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
                downloadProgress: nil,
                success: { [weak self] (task: URLSessionDataTask, responseObject: Any?) in
                    guard let self = self else { return }
                    context.response = task.response as? HTTPURLResponse
                    context.serializedObject = responseObject
                    if let data = responseObject as? Data {
                        context.mutableData = NSMutableData(data: data)
                    }
                    context.state = .finished
                    self.notifyMonitors { $0.requestDidFinish?(context) }
                    self.finalizeRequest(identifier: context.identifier)
                },
                failure: { [weak self] (task: URLSessionDataTask?, error: Error) in
                    guard let self = self else { return }
                    context.response = task?.response as? HTTPURLResponse
                    context.error = error
                    context.state = .finished
                    self.notifyMonitors { $0.requestDidFinish?(context) }
                    self.finalizeRequest(identifier: context.identifier)
                }
            )

            context.task = task
            context.state = .resumed
            task?.resume()

            self.notifyMonitors { $0.requestDidResume?(context) }
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
                self.notifyMonitors { $0.requestDidFinish?(context) }
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
                progress: nil,
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
                    self.notifyMonitors { $0.requestDidFinish?(context) }
                    self.finalizeRequest(identifier: context.identifier)
                }
            )

            context.task = task
            context.state = .resumed
            task.resume()

            self.notifyMonitors { $0.requestDidResume?(context) }
        }
    }

    // MARK: - 请求完成处理

    /// 从回调映射中取出 handler 并调用，然后移除活跃请求
    private func finalizeRequest(identifier: String) {
        lock.lock()
        let handler = completionHandlers.removeValue(forKey: identifier)
        self.activeRequests.removeValue(forKey: identifier)
        lock.unlock()
        handler?()
    }

    // MARK: - 回调注册

    internal func registerCompletion(for request: Request, handler: @escaping () -> Void) {
        lock.lock()
        if request.context.state == .finished {
            lock.unlock()
            handler()
        } else {
            completionHandlers[request.id] = handler
            lock.unlock()
        }
    }

    // 保留向后兼容
    internal func registerDownloadCompletion(for request: DownloadRequest, handler: @escaping () -> Void) {
        registerCompletion(for: request, handler: handler)
    }

    // MARK: - 请求跟踪

    private func trackRequest(_ request: Request) {
        lock.lock()
        activeRequests[request.id] = request
        lock.unlock()
    }

    // MARK: - 事件分发

    private func notifyMonitors(_ closure: (any EventMonitoring) -> Void) {
        guard !eventMonitors.isEmpty else { return }
        for monitor in eventMonitors {
            closure(monitor)
        }
    }
}
