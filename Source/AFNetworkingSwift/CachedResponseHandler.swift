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
@preconcurrency import AFNetworking

/// 控制响应是否写入缓存，对齐 Alamofire 的 `CachedResponseHandler` 概念。
/// 底层实现委托给 OC 层 `AFCachedResponseHandler` 协议。
public protocol CachedResponseHandler: Sendable {
    func dataTask(_ task: URLSessionDataTask,
                  willCacheResponse proposedResponse: CachedURLResponse) -> CachedURLResponse?
}

// MARK: - ResponseCacher

/// 简单缓存策略实现。底层委托给 OC `AFResponseCacher`。
public struct ResponseCacher: CachedResponseHandler, Sendable {

    public enum Behavior: Sendable {
        case cache
        case doNotCache
        case modify(@Sendable (URLSessionDataTask, CachedURLResponse) -> CachedURLResponse?)
    }

    public let behavior: Behavior
    private let _cacher: AFNetworking.AFResponseCacher

    public init(_ behavior: Behavior) {
        self.behavior = behavior
        switch behavior {
        case .cache:
            _cacher = AFNetworking.AFResponseCacher()
        case .doNotCache:
            _cacher = AFNetworking.AFResponseCacher.doNot()
        case .modify(let modifier):
            _cacher = AFNetworking.AFResponseCacher.modify { task, response in
                modifier(task, response)
            }
        }
    }

    public func dataTask(_ task: URLSessionDataTask,
                         willCacheResponse proposedResponse: CachedURLResponse) -> CachedURLResponse? {
        _cacher.dataTask(task, willCacheResponse: proposedResponse)
    }
}
