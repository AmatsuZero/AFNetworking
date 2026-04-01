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

/// 控制 HTTP 重定向行为，对齐 Alamofire 的 `RedirectHandler` 概念。
/// AFNetworking ObjC block 为同步返回值设计。
public protocol RedirectHandler: Sendable {
    /// 处理重定向，返回要跟随的请求，返回 `nil` 表示不跟随
    func task(_ task: URLSessionTask,
              willBeRedirectedTo request: URLRequest,
              for response: HTTPURLResponse) -> URLRequest?
}

// MARK: - Redirector

/// 简单重定向策略实现：始终跟随、始终拒绝或自定义修改。
public struct Redirector: RedirectHandler, Sendable {

    /// 重定向行为枚举
    public enum Behavior: Sendable {
        /// 跟随重定向（不修改请求）
        case follow
        /// 拒绝重定向
        case doNotFollow
        /// 使用自定义修改器
        case modify(@Sendable (URLSessionTask, URLRequest, HTTPURLResponse) -> URLRequest?)
    }

    public let behavior: Behavior

    public init(_ behavior: Behavior) {
        self.behavior = behavior
    }

    public func task(_ task: URLSessionTask,
                     willBeRedirectedTo request: URLRequest,
                     for response: HTTPURLResponse) -> URLRequest? {
        switch behavior {
        case .follow:
            return request
        case .doNotFollow:
            return nil
        case .modify(let modifier):
            return modifier(task, request, response)
        }
    }
}
