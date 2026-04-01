// UploadRequest.swift
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

/// 上传请求类型，继承 `DataRequest` 的响应序列化能力，新增上传进度回调。
public final class UploadRequest: DataRequest, @unchecked Sendable {

    // MARK: - Uploadable

    enum Uploadable {
        /// 上传 Data 体
        case data(Data)
        /// 上传本地文件
        case file(URL)
        /// 上传流
        case stream(InputStream)
        /// 构建 Multipart Form Data
        case multipartFormData((MultipartFormData) -> Void)
    }

    // MARK: - Properties

    let uploadable: Uploadable

    /// 上传进度回调（由 `uploadProgress(queue:closure:)` 设置，在 performUploadRequest 前读取）
    var uploadProgressHandler: (@Sendable (Progress) -> Void)?

    // MARK: - Init

    init(uploadable: Uploadable,
         context: RequestContext,
         session: Session,
         completionQueue: DispatchQueue = .main) {
        self.uploadable = uploadable
        super.init(context: context, session: session, completionQueue: completionQueue)
    }

    // MARK: - Progress

    /// 注册上传进度回调
    @discardableResult
    public func uploadProgress(queue: DispatchQueue = .main,
                               closure: @escaping @Sendable (Progress) -> Void) -> Self {
        uploadProgressHandler = { progress in
            queue.async { closure(progress) }
        }
        return self
    }
}
