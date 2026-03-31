// Concurrency.swift
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

// MARK: - DataRequest async/await

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension DataRequest {

    /// async 获取 Data 响应
    public func serializingData() async -> DataResponse<Data> {
        await withCheckedContinuation { continuation in
            responseData { response in
                continuation.resume(returning: response)
            }
        }
    }

    /// async 获取 String 响应
    public func serializingString(encoding: String.Encoding = .utf8) async -> DataResponse<String> {
        await withCheckedContinuation { continuation in
            responseString(encoding: encoding) { response in
                continuation.resume(returning: response)
            }
        }
    }

    /// async 获取 Decodable 响应
    public func serializingDecodable<T: Decodable & Sendable>(_ type: T.Type = T.self,
                                                    decoder: JSONDecoder = JSONDecoder()) async -> DataResponse<T> {
        await withCheckedContinuation { continuation in
            responseDecodable(of: type, decoder: decoder) { response in
                continuation.resume(returning: response)
            }
        }
    }

    /// async 获取 Data 值（成功时返回值，失败时抛出错误）
    public var value: Data {
        get async throws {
            let response = await serializingData()
            return try response.result.get()
        }
    }
}

// MARK: - DownloadRequest async/await

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension DownloadRequest {

    /// async 获取下载响应
    public func serializingDownload() async -> DownloadResponse<URL?> {
        await withCheckedContinuation { continuation in
            response { response in
                continuation.resume(returning: response)
            }
        }
    }

    /// async 获取下载文件 URL（成功时返回值，失败时抛出错误）
    public var fileURLValue: URL? {
        get async throws {
            let response = await serializingDownload()
            return try response.result.get()
        }
    }
}