// MultipartFormData.swift
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

/// Swift 门面类，包装 ObjC 的 `AFMultipartFormData` 协议。
/// 仅在 `Session.upload(multipartFormData:...)` 的构建闭包内有效。
public final class MultipartFormData {

    private let underlying: any AFMultipartFormData

    init(underlying: any AFMultipartFormData) {
        self.underlying = underlying
    }

    // MARK: - Append form field

    /// 追加表单字段（无文件名/MIME 类型）
    public func append(_ data: Data, withName name: String) {
        underlying.appendPart(withForm: data, name: name)
    }

    // MARK: - Append file data

    /// 追加文件数据，指定文件名和 MIME 类型
    public func append(_ data: Data, withName name: String, fileName: String, mimeType: String) {
        underlying.appendPart(withFileData: data, name: name, fileName: fileName, mimeType: mimeType)
    }

    // MARK: - Append file URL

    /// 追加文件 URL（自动推断文件名和 MIME 类型）
    public func append(_ fileURL: URL, withName name: String) throws {
        try underlying.appendPart(withFileURL: fileURL, name: name)
    }

    /// 追加文件 URL，手动指定文件名和 MIME 类型
    public func append(_ fileURL: URL, withName name: String, fileName: String, mimeType: String) throws {
        try underlying.appendPart(withFileURL: fileURL, name: name, fileName: fileName, mimeType: mimeType)
    }

    // MARK: - Append input stream

    /// 追加输入流
    public func append(_ stream: InputStream, withName name: String, fileName: String, length: Int64, mimeType: String) {
        underlying.appendPart(with: stream, name: name, fileName: fileName, length: length, mimeType: mimeType)
    }
}
