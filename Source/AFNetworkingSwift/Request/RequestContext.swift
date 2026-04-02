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
/// 底层实现委托给 OC 层 `AFRequestContext`（内部使用 os_unfair_lock 保证线程安全）。
public class RequestContext: @unchecked Sendable {

    /// 底层 OC 对象
    public let storage: AFRequestContext

    /// 请求描述（不可变配置）
    public let descriptor: RequestDescriptor

    /// 当前关联的 URLSessionTask
    public var task: URLSessionTask? {
        get { storage.task }
        set { storage.task = newValue }
    }

    /// 当前请求状态
    public var state: RequestState {
        get { RequestState(storage.state) }
        set { storage.state = newValue.objcState }
    }

    /// 原始请求（经过 adapter 修改后的最终请求）
    public var currentRequest: URLRequest? {
        get { storage.currentRequest }
        set { storage.currentRequest = newValue }
    }

    /// 初始请求（adapter 修改前的原始请求）
    public var initialRequest: URLRequest? {
        get { storage.initialRequest }
        set { storage.initialRequest = newValue }
    }

    /// 服务器响应
    public var response: HTTPURLResponse? {
        get { storage.response }
        set { storage.response = newValue }
    }

    /// 收集到的响应数据（data task 场景）
    public var mutableData: NSMutableData? {
        get { storage.mutableData }
        set { storage.mutableData = newValue }
    }

    /// 下载文件的本地 URL（download task 场景）
    public var fileURL: URL? {
        get { storage.fileURL }
        set { storage.fileURL = newValue }
    }

    /// 序列化后的响应对象
    public var serializedObject: Any? {
        get { storage.serializedObject }
        set { storage.serializedObject = newValue }
    }

    /// 请求过程中产生的错误
    public var error: (any Error)? {
        get { storage.error }
        set { storage.error = newValue as? NSError }
    }

    /// 任务指标
    public var metrics: URLSessionTaskMetrics? {
        get { storage.metrics }
        set { storage.metrics = newValue }
    }

    /// 当前重试次数
    public var retryCount: UInt {
        get { storage.retryCount }
        set { storage.retryCount = newValue }
    }

    /// 最大重试次数（0 表示不重试）
    public var maxRetryCount: UInt {
        get { storage.maxRetryCount }
        set { storage.maxRetryCount = newValue }
    }

    /// 请求创建时间
    public var createdAt: Date { storage.createdAt }

    /// 唯一标识符
    public var identifier: String { storage.identifier }

    /// 使用请求描述创建上下文
    public init(descriptor: RequestDescriptor) {
        self.storage = AFRequestContext(descriptor: descriptor.storage)
        self.descriptor = descriptor
    }

    /// 从 OC 对象创建
    internal init(storage: AFRequestContext) {
        self.storage = storage
        self.descriptor = RequestDescriptor(storage: storage.descriptor)
    }

    /// 获取已收集的响应数据（不可变副本，线程安全 — OC 层锁保护）
    public var data: Data? {
        storage.data()
    }

    /// 重置响应数据（用于重试场景，线程安全 — OC 层锁保护）
    public func resetResponseState() {
        storage.resetResponseState()
    }
}

extension RequestContext: CustomStringConvertible {
    public var description: String {
        "<RequestContext: \(identifier), state: \(state), url: \(descriptor.urlString)>"
    }
}
