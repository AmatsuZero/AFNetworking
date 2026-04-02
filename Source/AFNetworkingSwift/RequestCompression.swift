// RequestCompression.swift
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

// MARK: - DeflateRequestCompressor

/// 请求体压缩拦截器，对齐 Alamofire 的 `DeflateRequestCompressor`。
/// 底层委托给 OC 层 `AFDeflateRequestCompressor` 实现 zlib 压缩。
///
/// 用法：
/// ```swift
/// let session = Session(interceptor: DeflateRequestCompressor.default)
/// // 或 gzip
/// let session = Session(interceptor: DeflateRequestCompressor.gzip)
/// ```
public struct DeflateRequestCompressor: RequestInterceptor, @unchecked Sendable {

    /// 底层 OC 压缩器
    public let storage: AFDeflateRequestCompressor

    /// 默认实例（deflate，512 字节最小 body）
    public static let `default` = DeflateRequestCompressor(storage: .default())

    /// Gzip 实例
    public static let gzip = DeflateRequestCompressor(storage: .gzip())

    /// 压缩算法
    public var contentEncoding: ContentEncoding { storage.contentEncoding }

    /// 最小压缩 body 大小（字节）
    public var minimumBodySize: UInt { UInt(storage.minimumBodySize) }

    /// 使用默认配置创建
    public init() {
        self.storage = .default()
    }

    /// 自定义配置
    public init(contentEncoding: ContentEncoding = .deflate, minimumBodySize: UInt = 512) {
        self.storage = AFDeflateRequestCompressor(contentEncoding: contentEncoding, minimumBodySize: minimumBodySize)
    }

    /// 从 OC 对象创建
    public init(storage: AFDeflateRequestCompressor) {
        self.storage = storage
    }

    // MARK: - RequestAdapter（委托给 OC 层压缩）

    public func adaptRequest(_ request: URLRequest, completion: @escaping @Sendable (URLRequest?, (any Error)?) -> Void) {
        storage.adaptRequest(request, completion: completion)
    }

    // MARK: - RequestRetrier（不重试）

    public func shouldRetry(_ request: URLRequest, withError error: any Error, retryCount: UInt, completion: @escaping @Sendable (RetryResult, (any Error)?) -> Void) {
        completion(.doNotRetry, nil)
    }
}
