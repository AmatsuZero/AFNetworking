// EventMonitor.swift
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
import Combine

// MARK: - RequestEvent

/// 请求生命周期事件类型
public enum RequestEvent: Sendable {
    /// 请求已创建
    case created(RequestContext)
    /// 请求已被适配器修改
    case adapted(RequestContext, URLRequest)
    /// 请求适配失败
    case adaptFailed(RequestContext, any Error)
    /// 任务已恢复执行
    case resumed(RequestContext)
    /// 任务已暂停
    case suspended(RequestContext)
    /// 任务已取消
    case cancelled(RequestContext)
    /// 收到服务器响应
    case receivedResponse(RequestContext, HTTPURLResponse)
    /// 收到响应数据
    case receivedData(RequestContext, Data)
    /// 上传进度更新
    case uploadProgress(RequestContext, Progress)
    /// 下载进度更新
    case downloadProgress(RequestContext, Progress)
    /// 响应验证完成
    case validated(RequestContext, (any Error)?)
    /// 响应序列化完成
    case serialized(RequestContext, (any Sendable)?, (any Error)?)
    /// 请求将要重试
    case willRetry(RequestContext)
    /// 收集到任务指标
    case collectedMetrics(RequestContext, URLSessionTaskMetrics)
    /// 请求已完成
    case finished(RequestContext)
}

// MARK: - EventMonitor

/// Combine-based 事件监控器，通过 PassthroughSubject 发布请求生命周期事件。
/// 替代旧的 EventMonitoring 协议 + CompositeEventMonitor + ClosureEventMonitor 样板代码。
public final class EventMonitor: @unchecked Sendable {

    private let subject = PassthroughSubject<RequestEvent, Never>()

    /// 订阅所有请求事件的 Publisher
    public var eventPublisher: AnyPublisher<RequestEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    public init() {}

    /// 发布一个事件
    func send(_ event: RequestEvent) {
        subject.send(event)
    }
}

// MARK: - 便捷过滤扩展

public extension EventMonitor {

    /// 请求创建事件
    func onCreated() -> AnyPublisher<RequestContext, Never> {
        eventPublisher.compactMap {
            if case .created(let ctx) = $0 { return ctx } else { return nil }
        }.eraseToAnyPublisher()
    }

    /// 请求恢复执行事件
    func onResume() -> AnyPublisher<RequestContext, Never> {
        eventPublisher.compactMap {
            if case .resumed(let ctx) = $0 { return ctx } else { return nil }
        }.eraseToAnyPublisher()
    }

    /// 请求暂停事件
    func onSuspend() -> AnyPublisher<RequestContext, Never> {
        eventPublisher.compactMap {
            if case .suspended(let ctx) = $0 { return ctx } else { return nil }
        }.eraseToAnyPublisher()
    }

    /// 请求取消事件
    func onCancel() -> AnyPublisher<RequestContext, Never> {
        eventPublisher.compactMap {
            if case .cancelled(let ctx) = $0 { return ctx } else { return nil }
        }.eraseToAnyPublisher()
    }

    /// 请求完成事件
    func onFinish() -> AnyPublisher<RequestContext, Never> {
        eventPublisher.compactMap {
            if case .finished(let ctx) = $0 { return ctx } else { return nil }
        }.eraseToAnyPublisher()
    }

    /// 请求将要重试事件
    func onWillRetry() -> AnyPublisher<RequestContext, Never> {
        eventPublisher.compactMap {
            if case .willRetry(let ctx) = $0 { return ctx } else { return nil }
        }.eraseToAnyPublisher()
    }

    /// 收到服务器响应事件
    func onReceivedResponse() -> AnyPublisher<(RequestContext, HTTPURLResponse), Never> {
        eventPublisher.compactMap {
            if case .receivedResponse(let ctx, let resp) = $0 { return (ctx, resp) } else { return nil }
        }.eraseToAnyPublisher()
    }

    /// 收到数据事件
    func onReceivedData() -> AnyPublisher<(RequestContext, Data), Never> {
        eventPublisher.compactMap {
            if case .receivedData(let ctx, let data) = $0 { return (ctx, data) } else { return nil }
        }.eraseToAnyPublisher()
    }

    /// 任务指标收集事件
    func onCollectedMetrics() -> AnyPublisher<(RequestContext, URLSessionTaskMetrics), Never> {
        eventPublisher.compactMap {
            if case .collectedMetrics(let ctx, let metrics) = $0 { return (ctx, metrics) } else { return nil }
        }.eraseToAnyPublisher()
    }
}
