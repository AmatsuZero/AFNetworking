// DataResponse.swift
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

/// 泛型 Data 响应，对齐 Alamofire 的 `DataResponse<Success, Failure>`。
public struct DataResponse<Success>: @unchecked Sendable {
    /// 原始请求
    public let request: URLRequest?
    /// 服务器响应
    public let response: HTTPURLResponse?
    /// 原始响应数据
    public let data: Data?
    /// 任务指标
    public let metrics: URLSessionTaskMetrics?
    /// 序列化耗时
    public let serializationDuration: TimeInterval
    /// 结果
    public let result: Result<Success, Error>

    /// 成功时的值
    public var value: Success? { try? result.get() }
    /// 失败时的错误
    public var error: Error? {
        guard case .failure(let error) = result else { return nil }
        return error
    }

    public init(request: URLRequest?,
                response: HTTPURLResponse?,
                data: Data?,
                metrics: URLSessionTaskMetrics?,
                serializationDuration: TimeInterval,
                result: Result<Success, Error>) {
        self.request = request
        self.response = response
        self.data = data
        self.metrics = metrics
        self.serializationDuration = serializationDuration
        self.result = result
    }
}

extension DataResponse: CustomStringConvertible {
    public var description: String {
        let status = response.map { "\($0.statusCode)" } ?? "nil"
        switch result {
        case .success:
            return "[DataResponse] Status: \(status), Success"
        case .failure(let error):
            return "[DataResponse] Status: \(status), Failure: \(error.localizedDescription)"
        }
    }
}

/// 泛型 Download 响应，对齐 Alamofire 的 `DownloadResponse<Success, Failure>`。
public struct DownloadResponse<Success>: @unchecked Sendable {
    /// 原始请求
    public let request: URLRequest?
    /// 服务器响应
    public let response: HTTPURLResponse?
    /// 下载文件 URL
    public let fileURL: URL?
    /// 恢复数据
    public let resumeData: Data?
    /// 任务指标
    public let metrics: URLSessionTaskMetrics?
    /// 序列化耗时
    public let serializationDuration: TimeInterval
    /// 结果
    public let result: Result<Success, Error>

    /// 成功时的值
    public var value: Success? { try? result.get() }
    /// 失败时的错误
    public var error: Error? {
        guard case .failure(let error) = result else { return nil }
        return error
    }

    public init(request: URLRequest?,
                response: HTTPURLResponse?,
                fileURL: URL?,
                resumeData: Data?,
                metrics: URLSessionTaskMetrics?,
                serializationDuration: TimeInterval,
                result: Result<Success, Error>) {
        self.request = request
        self.response = response
        self.fileURL = fileURL
        self.resumeData = resumeData
        self.metrics = metrics
        self.serializationDuration = serializationDuration
        self.result = result
    }
}

extension DownloadResponse: CustomStringConvertible {
    public var description: String {
        let status = response.map { "\($0.statusCode)" } ?? "nil"
        switch result {
        case .success:
            return "[DownloadResponse] Status: \(status), Success, fileURL: \(fileURL?.absoluteString ?? "nil")"
        case .failure(let error):
            return "[DownloadResponse] Status: \(status), Failure: \(error.localizedDescription)"
        }
    }
}