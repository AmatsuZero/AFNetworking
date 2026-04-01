// DownloadRequest.swift
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

/// 下载文件目标配置
public struct DownloadDestination: Sendable {
    /// 目标文件 URL 生成闭包
    public let handler: @Sendable (_ temporaryURL: URL, _ response: HTTPURLResponse) -> (URL, Options)

    /// 下载选项
    public struct Options: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        /// 如果目标文件已存在，先移除
        public static let removePreviousFile = Options(rawValue: 1 << 0)
        /// 创建中间目录
        public static let createIntermediateDirectories = Options(rawValue: 1 << 1)
    }

    public init(handler: @escaping @Sendable (_ temporaryURL: URL, _ response: HTTPURLResponse) -> (URL, Options)) {
        self.handler = handler
    }

    /// 建议的下载目标（使用系统建议的文件名）
    public static let suggestedDownloadDestination: DownloadDestination = {
        DownloadDestination { temporaryURL, response in
            let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let suggestedFilename = response.suggestedFilename ?? temporaryURL.lastPathComponent
            let url = directoryURLs[0].appendingPathComponent(suggestedFilename)
            return (url, [.removePreviousFile, .createIntermediateDirectories])
        }
    }()
}

/// 下载请求类型，对齐 Alamofire 的 `DownloadRequest`。
public final class DownloadRequest: Request, @unchecked Sendable {

    /// 下载文件的本地 URL
    public var fileURL: URL? { context.fileURL }

    /// 下载目标配置
    public let destination: DownloadDestination?

    init(context: RequestContext, session: Session, destination: DownloadDestination?,
         completionQueue: DispatchQueue = .main) {
        self.destination = destination
        super.init(context: context, session: session, completionQueue: completionQueue)
    }

    // MARK: - 响应处理

    /// 通用下载响应序列化骨架：注册完成回调 → 验证 → 序列化 → 构建 DownloadResponse → 分发。
    private func appendDownloadResponseSerializer<T>(
        queue: DispatchQueue?,
        serialize: @escaping @Sendable (_ fileURL: URL?, _ error: Error?) -> Result<T, Error>,
        completionHandler: @escaping @Sendable (DownloadResponse<T>) -> Void
    ) {
        session?.registerDownloadCompletion(for: self) { [self] in
            let validationError = self.performValidation(data: nil)
            let finalError = validationError ?? self.context.error
            let result = serialize(self.context.fileURL, finalError)

            let response = DownloadResponse<T>(
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
    }

    /// 下载完成回调（返回文件 URL）
    @discardableResult
    public func response(queue: DispatchQueue? = nil,
                         completionHandler: @escaping @Sendable (DownloadResponse<URL?>) -> Void) -> Self {
        appendDownloadResponseSerializer(queue: queue, serialize: { fileURL, error in
            error == nil ? .success(fileURL) : .failure(error!)
        }, completionHandler: completionHandler)
        return self
    }

    /// 读取下载文件内容为 Data
    @discardableResult
    public func responseData(queue: DispatchQueue? = nil,
                             completionHandler: @escaping @Sendable (DownloadResponse<Data>) -> Void) -> Self {
        appendDownloadResponseSerializer(queue: queue, serialize: { fileURL, error in
            if let error { return .failure(error) }
            guard let url = fileURL else {
                return .failure(AFError.responseSerializationFailed(reason: "Download fileURL was nil"))
            }
            do {
                return .success(try Data(contentsOf: url))
            } catch {
                return .failure(error)
            }
        }, completionHandler: completionHandler)
        return self
    }

    /// 读取下载文件内容为 String
    @discardableResult
    public func responseString(queue: DispatchQueue? = nil,
                               encoding: String.Encoding = .utf8,
                               completionHandler: @escaping @Sendable (DownloadResponse<String>) -> Void) -> Self {
        appendDownloadResponseSerializer(queue: queue, serialize: { fileURL, error in
            if let error { return .failure(error) }
            guard let url = fileURL else {
                return .failure(AFError.responseSerializationFailed(reason: "Download fileURL was nil"))
            }
            do {
                let data = try Data(contentsOf: url)
                return .success(String(data: data, encoding: encoding) ?? "")
            } catch {
                return .failure(error)
            }
        }, completionHandler: completionHandler)
        return self
    }

    /// 将下载文件内容反序列化为 Decodable 模型
    @discardableResult
    public func responseDecodable<T: Decodable & Sendable>(of type: T.Type = T.self,
                                                           queue: DispatchQueue? = nil,
                                                           decoder: JSONDecoder = JSONDecoder(),
                                                           completionHandler: @escaping @Sendable (DownloadResponse<T>) -> Void) -> Self {
        appendDownloadResponseSerializer(queue: queue, serialize: { fileURL, error in
            if let error { return .failure(error) }
            guard let url = fileURL else {
                return .failure(AFError.responseSerializationFailed(reason: "Download fileURL was nil"))
            }
            do {
                let data = try Data(contentsOf: url)
                return .success(try decoder.decode(T.self, from: data))
            } catch {
                return .failure(error)
            }
        }, completionHandler: completionHandler)
        return self
    }
}
