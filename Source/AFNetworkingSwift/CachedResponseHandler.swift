// CachedResponseHandler.swift
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

/// 控制响应是否写入缓存，对齐 Alamofire 的 `CachedResponseHandler` 概念。
/// AFNetworking ObjC block 为同步返回值设计。
public protocol CachedResponseHandler: Sendable {
    /// 决定如何处理缓存响应
    /// - Returns: 要缓存的响应（可修改），返回 `nil` 表示不缓存
    func dataTask(_ task: URLSessionDataTask,
                  willCacheResponse proposedResponse: CachedURLResponse) -> CachedURLResponse?
}

// MARK: - ResponseCacher

/// 简单缓存策略实现：始终缓存或始终不缓存。
public struct ResponseCacher: CachedResponseHandler, Sendable {

    /// 缓存行为枚举
    public enum Behavior: Sendable {
        /// 按建议缓存
        case cache
        /// 不缓存
        case doNotCache
        /// 使用自定义修改器
        case modify(@Sendable (URLSessionDataTask, CachedURLResponse) -> CachedURLResponse?)
    }

    public let behavior: Behavior

    public init(_ behavior: Behavior) {
        self.behavior = behavior
    }

    public func dataTask(_ task: URLSessionDataTask,
                         willCacheResponse proposedResponse: CachedURLResponse) -> CachedURLResponse? {
        switch behavior {
        case .cache:
            return proposedResponse
        case .doNotCache:
            return nil
        case .modify(let modifier):
            return modifier(task, proposedResponse)
        }
    }
}
