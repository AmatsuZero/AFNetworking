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

    /// async 获取 Data 响应（带 Task 取消集成）
    public func serializingData() async -> DataResponse<Data> {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                responseData { response in
                    continuation.resume(returning: response)
                }
            }
        } onCancel: { [weak self] in
            self?.cancel()
        }
    }

    /// async 获取 String 响应（带 Task 取消集成）
    public func serializingString(encoding: String.Encoding = .utf8) async -> DataResponse<String> {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                responseString(encoding: encoding) { response in
                    continuation.resume(returning: response)
                }
            }
        } onCancel: { [weak self] in
            self?.cancel()
        }
    }

    /// async 获取 Decodable 响应（带 Task 取消集成）
    public func serializingDecodable<T: Decodable & Sendable>(_ type: T.Type = T.self,
                                                    decoder: JSONDecoder = JSONDecoder()) async -> DataResponse<T> {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                responseDecodable(of: type, decoder: decoder) { response in
                    continuation.resume(returning: response)
                }
            }
        } onCancel: { [weak self] in
            self?.cancel()
        }
    }

    /// async 获取 Data 值（成功时返回值，失败时抛出错误）+ Task 取消
    public var value: Data {
        get async throws {
            let response = await serializingData()
            return try response.result.get()
        }
    }

    // MARK: - 便捷 async 方法

    /// async 获取 Data（直接返回 Data 或抛出错误）
    public func data() async throws -> DataResponse<Data> {
        await serializingData()
    }

    /// async 获取 String
    public func string(encoding: String.Encoding = .utf8) async throws -> DataResponse<String> {
        await serializingString(encoding: encoding)
    }

    /// async 获取 Decodable 模型
    public func decodable<T: Decodable & Sendable>(of type: T.Type = T.self,
                                                    decoder: JSONDecoder = JSONDecoder()) async throws -> DataResponse<T> {
        await serializingDecodable(type, decoder: decoder)
    }
}

// MARK: - DownloadRequest async/await

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension DownloadRequest {

    /// async 获取下载响应（带 Task 取消集成）
    public func serializingDownload() async -> DownloadResponse<URL?> {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                response { response in
                    continuation.resume(returning: response)
                }
            }
        } onCancel: { [weak self] in
            self?.cancel()
        }
    }

    /// async 获取下载文件 URL（成功时返回值，失败时抛出错误）
    public var fileURLValue: URL? {
        get async throws {
            let response = await serializingDownload()
            return try response.result.get()
        }
    }

    /// async 便捷方法获取下载响应
    public func download() async throws -> DownloadResponse<URL?> {
        await serializingDownload()
    }
}

// MARK: - Session async 便捷方法

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Session {

    /// async 发起 GET 请求并返回 Data 响应
    func data(from url: String,
              method: HTTPMethod = .get,
              parameters: [String: Any]? = nil,
              encoding: ParameterEncoding = .auto,
              headers: HTTPHeaders? = nil) async -> DataResponse<Data> {
        await request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
            .validate()
            .serializingData()
    }

    /// async 发起请求并返回 Decodable 模型响应
    func decodable<T: Decodable & Sendable>(of type: T.Type,
                                             from url: String,
                                             method: HTTPMethod = .get,
                                             parameters: [String: Any]? = nil,
                                             encoding: ParameterEncoding = .auto,
                                             headers: HTTPHeaders? = nil,
                                             decoder: JSONDecoder = JSONDecoder()) async -> DataResponse<T> {
        await request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
            .validate()
            .serializingDecodable(type, decoder: decoder)
    }

    /// async 发起请求并返回 String 响应
    func string(from url: String,
                method: HTTPMethod = .get,
                parameters: [String: Any]? = nil,
                encoding: ParameterEncoding = .auto,
                headers: HTTPHeaders? = nil) async -> DataResponse<String> {
        await request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
            .validate()
            .serializingString()
    }
}

// MARK: - Authenticator async 扩展

/// 为 Authenticator 提供 async throws 版本的 refresh，默认桥接 callback API。
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Authenticator {
    /// async 版本的凭据刷新
    func refresh(_ credential: Credential, for session: Session) async throws -> Credential {
        try await withCheckedThrowingContinuation { continuation in
            refresh(credential, for: session) { @Sendable result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - AsyncSequence 进度流（可选 P2）

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension DataRequest {
    /// 上传/下载进度 AsyncStream
    /// 注意：需要底层支持进度回调后方可生效。当前为框架预留接口。
    public var progress: AsyncStream<Progress> {
        AsyncStream { continuation in
            // 预留：当 performDataRequest 支持 progress 回调后，在此接入
            // 目前立即结束流
            continuation.finish()
        }
    }
}
