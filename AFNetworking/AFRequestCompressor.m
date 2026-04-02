// AFRequestCompressor.m
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

#import "AFRequestCompressor.h"
#import <zlib.h>

static NSString * const AFRequestCompressorErrorDomain = @"com.alamofire.error.requestcompressor";

static NSString *AFContentEncodingHeaderValue(AFContentEncoding encoding) {
    switch (encoding) {
        case AFContentEncodingDeflate: return @"deflate";
        case AFContentEncodingGzip:    return @"gzip";
    }
}

@implementation AFDeflateRequestCompressor

+ (instancetype)defaultCompressor {
    return [[self alloc] initWithContentEncoding:AFContentEncodingDeflate minimumBodySize:512];
}

+ (instancetype)gzipCompressor {
    return [[self alloc] initWithContentEncoding:AFContentEncodingGzip minimumBodySize:512];
}

- (instancetype)init {
    return [self initWithContentEncoding:AFContentEncodingDeflate minimumBodySize:512];
}

- (instancetype)initWithContentEncoding:(AFContentEncoding)encoding
                        minimumBodySize:(NSUInteger)minimumBodySize {
    self = [super init];
    if (self) {
        _contentEncoding = encoding;
        _minimumBodySize = minimumBodySize;
    }
    return self;
}

- (nullable NSData *)compressData:(NSData *)data error:(NSError **)error {
    if (data.length == 0) {
        return data;
    }

    z_stream stream;
    memset(&stream, 0, sizeof(stream));

    int windowBits;
    switch (self.contentEncoding) {
        case AFContentEncodingDeflate:
            windowBits = -MAX_WBITS; // raw deflate
            break;
        case AFContentEncodingGzip:
            windowBits = MAX_WBITS + 16; // gzip
            break;
    }

    int status = deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED,
                              windowBits, 8, Z_DEFAULT_STRATEGY);
    if (status != Z_OK) {
        if (error) {
            *error = [NSError errorWithDomain:AFRequestCompressorErrorDomain
                                         code:status
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to initialize zlib deflate"}];
        }
        return nil;
    }

    stream.next_in = (Bytef *)data.bytes;
    stream.avail_in = (uInt)data.length;

    NSMutableData *compressed = [NSMutableData dataWithLength:deflateBound(&stream, (uLong)data.length)];
    stream.next_out = (Bytef *)compressed.mutableBytes;
    stream.avail_out = (uInt)compressed.length;

    status = deflate(&stream, Z_FINISH);
    deflateEnd(&stream);

    if (status != Z_STREAM_END) {
        if (error) {
            *error = [NSError errorWithDomain:AFRequestCompressorErrorDomain
                                         code:status
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to compress data with zlib"}];
        }
        return nil;
    }

    compressed.length = stream.total_out;
    return [compressed copy];
}

#pragma mark - AFRequestAdapter

- (void)adaptRequest:(NSURLRequest *)request
          completion:(void (^)(NSURLRequest * _Nullable, NSError * _Nullable))completion {
    NSData *body = request.HTTPBody;

    // 没有 body 或 body 太小，不压缩
    if (!body || body.length < self.minimumBodySize) {
        completion(request, nil);
        return;
    }

    // 已经有 Content-Encoding，不重复压缩
    if ([request valueForHTTPHeaderField:@"Content-Encoding"]) {
        completion(request, nil);
        return;
    }

    NSError *compressError = nil;
    NSData *compressedData = [self compressData:body error:&compressError];

    if (compressError || !compressedData) {
        completion(nil, compressError);
        return;
    }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    mutableRequest.HTTPBody = compressedData;
    [mutableRequest setValue:AFContentEncodingHeaderValue(self.contentEncoding)
         forHTTPHeaderField:@"Content-Encoding"];
    completion(mutableRequest, nil);
}

@end
