// Request.swift
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

/// 请求基类，对齐 Alamofire 的 `Request`。
/// 持有 `RequestContext`，提供链式配置和生命周期控制。
open class Request: @unchecked Sendable {

    // MARK: - 属性

    /// 底层请求上下文
    internal let context: RequestContext

    /// 关联的 Session
    public weak var session: Session?

    /// 请求唯一标识
    public var id: String { context.identifier }

    /// 当前请求状态
    public var state: RequestState { context.state }

    /// 底层 URLSessionTask
    public var task: URLSessionTask? { context.task }

    /// 原始请求
    public var request: URLRequest? { context.currentRequest }

    /// 服务器响应
    public var response: HTTPURLResponse? { context.response }

    /// 重试次数
    public var retryCount: UInt { context.retryCount }

    /// 验证器列表
    internal var validators: [any ResponseValidating] = []

    /// 完成回调队列
    internal let completionQueue: DispatchQueue

    // MARK: - 初始化

    init(context: RequestContext, session: Session, completionQueue: DispatchQueue = .main) {
        self.context = context
        self.session = session
        self.completionQueue = completionQueue
    }

    // MARK: - 生命周期控制

    /// 恢复请求
    @discardableResult
    public func resume() -> Self {
        context.task?.resume()
        context.state = .resumed
        return self
    }

    /// 暂停请求
    @discardableResult
    public func suspend() -> Self {
        context.task?.suspend()
        context.state = .suspended
        return self
    }

    /// 取消请求
    @discardableResult
    public func cancel() -> Self {
        context.task?.cancel()
        context.state = .cancelled
        return self
    }

    // MARK: - 链式验证

    /// 使用默认规则验证响应（状态码 200-299，Content-Type 匹配 Accept）
    @discardableResult
    public func validate() -> Self {
        validators.append(StatusCodeValidator.default())
        return self
    }

    /// 验证响应状态码
    /// - Parameter range: 可接受的状态码范围
    @discardableResult
    public func validate<S: Sequence>(statusCode acceptableStatusCodes: S) -> Self where S.Iterator.Element == Int {
        let indexSet = NSMutableIndexSet()
        for code in acceptableStatusCodes {
            indexSet.add(code)
        }
        validators.append(StatusCodeValidator(acceptableStatusCodes: indexSet as IndexSet))
        return self
    }

    /// 验证响应 Content-Type
    /// - Parameter contentType: 可接受的 Content-Type 集合
    @discardableResult
    public func validate(contentType acceptableContentTypes: [String]) -> Self {
        validators.append(ContentTypeValidator(acceptableContentTypes: Set(acceptableContentTypes)))
        return self
    }

    /// 自定义验证
    /// - Parameter validation: 验证闭包
    @discardableResult
    public func validate(_ validation: @escaping @Sendable (URLRequest?, HTTPURLResponse, Data?) -> Error?) -> Self {
        let block = BlockResponseValidator { request, response, data in
            return validation(request, response, data) as NSError?
        }
        validators.append(block)
        return self
    }

    // MARK: - 调试

    /// 生成 cURL 命令描述
    /// - Parameter handler: 接收 cURL 字符串的闭包
    @discardableResult
    public func cURLDescription(calling handler: @escaping @Sendable (String) -> Void) -> Self {
        completionQueue.async { [weak self] in
            guard let request = self?.context.currentRequest else {
                handler("$ curl command could not be created")
                return
            }
            var components = ["$ curl -v"]
            components.append("-X \(request.httpMethod ?? "GET")")

            if let headers = request.allHTTPHeaderFields {
                for (name, value) in headers.sorted(by: { $0.key < $1.key }) {
                    let escapedValue = value.replacingOccurrences(of: "'", with: "'\\''")
                    components.append("-H '\(name): \(escapedValue)'")
                }
            }

            if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                let escapedBody = bodyString.replacingOccurrences(of: "'", with: "'\\''")
                components.append("-d '\(escapedBody)'")
            }

            components.append("'\(request.url?.absoluteString ?? "")'")
            handler(components.joined(separator: " \\\n\t"))
        }
        return self
    }

    // MARK: - 共享内部方法

    /// 执行响应验证
    internal func performValidation(data: Data? = nil) -> Error? {
        guard let httpResponse = context.response else { return nil }
        let validationData = data ?? context.data
        for validator in validators {
            if let error = validator.validate(context.currentRequest, response: httpResponse, data: validationData) {
                return error
            }
        }
        return nil
    }

    /// 获取请求指标（如可用）
    internal var metricsIfAvailable: URLSessionTaskMetrics? {
        context.metrics
    }

    /// 将回调分发到指定队列
    internal func dispatchCallback(on queue: DispatchQueue?, execute work: @escaping @Sendable () -> Void) {
        if let queue = queue {
            queue.async { work() }
        } else {
            work()
        }
    }
}

// MARK: - CustomStringConvertible

extension Request: CustomStringConvertible {
    public var description: String {
        "\(context)"
    }
}

// MARK: - Hashable & Equatable

extension Request: Equatable, Hashable {
    public static func == (lhs: Request, rhs: Request) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
