// RequestContext.swift
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

/// 单个请求的运行时上下文，关联 URLSessionTask 与请求生命周期中的所有状态。
/// 纯 Swift class — 仅在 Swift 闭包内访问。
public class RequestContext: @unchecked Sendable {

    /// 请求描述（不可变配置）
    public let descriptor: RequestDescriptor

    /// 当前关联的 URLSessionTask
    public var task: URLSessionTask?

    /// 当前请求状态
    public var state: RequestState = .initialized

    /// 原始请求（经过 adapter 修改后的最终请求）
    public var currentRequest: URLRequest?

    /// 初始请求（adapter 修改前的原始请求）
    public var initialRequest: URLRequest?

    /// 服务器响应
    public var response: HTTPURLResponse?

    /// 收集到的响应数据（data task 场景）
    public var mutableData: NSMutableData?

    /// 下载文件的本地 URL（download task 场景）
    public var fileURL: URL?

    /// 序列化后的响应对象
    public var serializedObject: Any?

    /// 请求过程中产生的错误
    public var error: (any Error)?

    /// 任务指标
    public var metrics: URLSessionTaskMetrics?

    /// 当前重试次数
    public var retryCount: UInt = 0

    /// 最大重试次数（0 表示不重试）
    public var maxRetryCount: UInt = 0

    /// 请求创建时间
    public let createdAt: Date

    /// 唯一标识符
    public let identifier: String

    /// 使用请求描述创建上下文
    public init(descriptor: RequestDescriptor) {
        self.descriptor = descriptor
        self.createdAt = Date()
        self.identifier = UUID().uuidString
    }

    /// 获取已收集的响应数据（不可变副本）
    public var data: Data? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return mutableData.map { Data($0) }
    }

    /// 重置响应数据（用于重试场景）
    public func resetResponseState() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        mutableData = nil
        response = nil
        fileURL = nil
        serializedObject = nil
        error = nil
        metrics = nil
    }
}

extension RequestContext: CustomStringConvertible {
    public var description: String {
        "<RequestContext: \(identifier), state: \(state), url: \(descriptor.urlString)>"
    }
}
