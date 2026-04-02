// ParameterEncoding.swift
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

import AFNetworking

/// 参数编码位置
public enum ParameterEncoding: Int, Sendable {
    /// 自动：GET/HEAD/DELETE 放 URL，其他放 Body
    case auto = 0
    /// 强制 URL 查询参数编码
    case urlQuery
    /// 强制 HTTP Body 编码
    case httpBody
    /// JSON Body 编码
    case json
    /// Property List Body 编码
    case propertyList

    // MARK: - OC Bridging

    init(_ objcEncoding: AFParameterEncoding) {
        self.init(rawValue: objcEncoding.rawValue)!
    }

    var objcEncoding: AFParameterEncoding {
        AFParameterEncoding(rawValue: rawValue)!
    }
}
