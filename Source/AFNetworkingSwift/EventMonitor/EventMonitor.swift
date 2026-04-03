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
import AFNetworking

// MARK: - OC types re-exported

/// 事件监控 delegate 协议（OC 层）
public typealias EventMonitorDelegate = AFEventMonitorDelegate

/// 事件监控中心（OC 层，用于 OC 用户直接使用）
public typealias EventMonitorCenter = AFEventMonitorCenter

// MARK: - RequestEvent

/// 请求生命周期事件类型（Swift 层内部使用）
public enum RequestEvent: Sendable {
    case created(RequestContext)
    case resumed(RequestContext)
    case suspended(RequestContext)
    case cancelled(RequestContext)
    case finished(RequestContext)
    /// 流式请求收到数据块
    case didReceiveData(RequestContext, Data)
    /// 流式请求收到 HTTP 响应头
    case didReceiveResponse(RequestContext, HTTPURLResponse)
}

// MARK: - Request Notification Names

/// 请求生命周期 NSNotification 名称，对齐 Alamofire 的通知常量。
/// OC 和 Swift 用户均可通过 `NotificationCenter.default` 监听。
public extension Request {
    /// 请求已恢复执行
    static let didResumeNotification = Notification.Name(rawValue: "com.alamofire.notification.request.didResume")
    /// 请求已暂停
    static let didSuspendNotification = Notification.Name(rawValue: "com.alamofire.notification.request.didSuspend")
    /// 请求已取消
    static let didCancelNotification = Notification.Name(rawValue: "com.alamofire.notification.request.didCancel")
    /// 请求已完成
    static let didFinishNotification = Notification.Name(rawValue: "com.alamofire.notification.request.didFinish")
}

// MARK: - EventMonitor (Swift 层轻量事件分发器)

/// Swift 层事件监控器。
/// OC 用户使用 `AFEventMonitorCenter` + delegate 模式。
/// 同时通过 `NotificationCenter.default` 发送 NSNotification，方便两层监听。
public final class EventMonitor: @unchecked Sendable {

    public init() {}

    /// 发布一个事件，桥接到 OC AFEventMonitorCenter 并发送 NSNotification
    func send(_ event: RequestEvent) {
        let center = AFEventMonitorCenter.shared()
        switch event {
        case .created(let ctx):
            center.notifyRequestDidCreate(ctx.storage)
        case .resumed(let ctx):
            center.notifyRequestDidResume(ctx.storage)
            postNotification(Request.didResumeNotification, context: ctx)
        case .suspended(let ctx):
            center.notifyRequestDidSuspend(ctx.storage)
            postNotification(Request.didSuspendNotification, context: ctx)
        case .cancelled(let ctx):
            center.notifyRequestDidCancel(ctx.storage)
            postNotification(Request.didCancelNotification, context: ctx)
        case .finished(let ctx):
            center.notifyRequestDidFinish(ctx.storage)
            postNotification(Request.didFinishNotification, context: ctx)
        case .didReceiveData(let ctx, let data):
            // OC 方法 notifyRequest:didReceiveData: 与 notifyRequest:didReceiveResponse:
            // 在 Swift 中均被重命名为 didReceive:，导致歧义。直接使用 OC selector 调用。
            let selector = NSSelectorFromString("notifyRequest:didReceiveData:")
            if center.responds(to: selector) {
                center.perform(selector, with: ctx.storage, with: data as NSData)
            }
        case .didReceiveResponse(let ctx, let response):
            center.notifyRequest(ctx.storage, didReceive: response)
        }
    }

    /// 发送 NSNotification，userInfo 包含 RequestContext
    private func postNotification(_ name: Notification.Name, context: RequestContext) {
        NotificationCenter.default.post(name: name, object: context, userInfo: ["context": context])
    }
}
