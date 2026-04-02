// AFRequestCompressor.h
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

#import <Foundation/Foundation.h>
#import "AFRequestInterceptor.h"
#import "AFCompatibilityMacros.h"

NS_ASSUME_NONNULL_BEGIN

/// 请求体压缩算法
typedef NS_ENUM(NSUInteger, AFContentEncoding) {
    /// Deflate 压缩（zlib）
    AFContentEncodingDeflate = 0,
    /// Gzip 压缩
    AFContentEncodingGzip,
} NS_SWIFT_NAME(ContentEncoding);

/// 请求体压缩适配器，对齐 Alamofire 的 `DeflateRequestCompressor`。
/// 使用 zlib 压缩请求的 httpBody，并设置 Content-Encoding 头。
///
/// 用法（OC）：
/// @code
/// AFDeflateRequestCompressor *compressor = [AFDeflateRequestCompressor defaultCompressor];
/// // 作为 AFRequestAdapter 使用
/// @endcode
AF_SWIFT_SENDABLE
@interface AFDeflateRequestCompressor : NSObject <AFRequestAdapter>

/// 压缩算法，默认 deflate
@property (nonatomic, assign, readonly) AFContentEncoding contentEncoding;

/// 是否应压缩的最小 body 大小（字节），默认 512
/// 小于此大小的 body 不压缩（压缩开销可能大于收益）
@property (nonatomic, assign, readonly) NSUInteger minimumBodySize;

/// 使用默认配置创建（deflate，512 字节最小 body）
+ (instancetype)defaultCompressor;

/// 使用 gzip 配置创建
+ (instancetype)gzipCompressor;

/// 完整初始化
- (instancetype)initWithContentEncoding:(AFContentEncoding)encoding
                        minimumBodySize:(NSUInteger)minimumBodySize NS_DESIGNATED_INITIALIZER;

/// 压缩数据
/// @param data 原始数据
/// @param error 错误输出
/// @return 压缩后的数据，失败返回 nil
- (nullable NSData *)compressData:(NSData *)data error:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
