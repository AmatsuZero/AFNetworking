// DataStreamSerializer.swift
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

// MARK: - DataStreamSerializer

/// 流式数据序列化协议，对齐 Alamofire 的 `DataStreamSerializer`。
/// 与 `DataResponseSerializerProtocol` 不同，此协议仅处理单个数据块，而非完整响应。
public protocol DataStreamSerializer: Sendable {
    associatedtype SerializedObject: Sendable

    /// 将单个数据块序列化为目标类型。
    /// - Parameter data: 从服务器接收到的单个数据块。
    /// - Returns: 序列化后的对象。
    func serialize(_ data: Data) throws -> SerializedObject
}

// MARK: - PassthroughStreamSerializer

/// 直通流式序列化器，不做任何转换，直接返回原始 Data。
/// 对齐 Alamofire 的 `PassthroughStreamSerializer`。
public struct PassthroughStreamSerializer: DataStreamSerializer {
    public init() {}

    public func serialize(_ data: Data) throws -> Data {
        data
    }
}

// MARK: - StringStreamSerializer

/// 字符串流式序列化器，将数据块解码为 UTF8 字符串。
/// 对齐 Alamofire 的 `StringStreamSerializer`。
public struct StringStreamSerializer: DataStreamSerializer {
    public init() {}

    public func serialize(_ data: Data) throws -> String {
        String(decoding: data, as: UTF8.self)
    }
}

// MARK: - DecodableStreamSerializer

/// Decodable 流式序列化器，将每个数据块解码为指定的 Decodable 类型。
/// 对齐 Alamofire 的 `DecodableStreamSerializer`。
public struct DecodableStreamSerializer<T: Decodable & Sendable>: DataStreamSerializer, @unchecked Sendable {
    /// 数据解码器（默认 JSONDecoder）
    public let decoder: any DataDecoder
    /// 数据预处理器（默认直通）
    public let preprocessor: any DataPreprocessor

    public init(decoder: any DataDecoder = JSONDecoder(),
                preprocessor: any DataPreprocessor = PassthroughPreprocessor()) {
        self.decoder = decoder
        self.preprocessor = preprocessor
    }

    public func serialize(_ data: Data) throws -> T {
        let preprocessed = try preprocessor.preprocess(data)
        return try decoder.decode(T.self, from: preprocessed)
    }
}
