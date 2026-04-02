// RedirectHandler.swift
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

/// 控制 HTTP 重定向行为，对齐 Alamofire 的 `RedirectHandler` 概念。
/// 底层实现委托给 OC 层 `AFRedirectHandler` 协议。
public protocol RedirectHandler: Sendable {
    func task(_ task: URLSessionTask,
              willBeRedirectedTo request: URLRequest,
              for response: HTTPURLResponse) -> URLRequest?
}

// MARK: - Redirector

/// 简单重定向策略实现。底层委托给 OC `AFRedirector`。
public struct Redirector: RedirectHandler, Sendable {

    public enum Behavior: Sendable {
        case follow
        case doNotFollow
        case modify(@Sendable (URLSessionTask, URLRequest, HTTPURLResponse) -> URLRequest?)
    }

    public let behavior: Behavior
    private let _redirector: AFNetworking.AFRedirector

    public init(_ behavior: Behavior) {
        self.behavior = behavior
        switch behavior {
        case .follow:
            _redirector = .follower()
        case .doNotFollow:
            _redirector = .doNotFollower()
        case .modify(let modifier):
            _redirector = .modify { task, request, response in
                modifier(task, request, response)
            }
        }
    }

    public func task(_ task: URLSessionTask,
                     willBeRedirectedTo request: URLRequest,
                     for response: HTTPURLResponse) -> URLRequest? {
        _redirector.task(task, willBeRedirectedTo: request, for: response)
    }
}
