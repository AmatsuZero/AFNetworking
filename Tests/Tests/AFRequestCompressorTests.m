// AFRequestCompressorTests.m

#import <XCTest/XCTest.h>
#import "AFRequestCompressor.h"
#import <zlib.h>

@interface AFRequestCompressorTests : XCTestCase
@end

@implementation AFRequestCompressorTests

#pragma mark - Default Properties

- (void)testDefaultCompressorProperties {
    AFDeflateRequestCompressor *compressor = [AFDeflateRequestCompressor defaultCompressor];
    XCTAssertEqual(compressor.contentEncoding, AFContentEncodingDeflate);
    XCTAssertEqual(compressor.minimumBodySize, 512);
}

- (void)testGzipCompressorProperties {
    AFDeflateRequestCompressor *compressor = [AFDeflateRequestCompressor gzipCompressor];
    XCTAssertEqual(compressor.contentEncoding, AFContentEncodingGzip);
    XCTAssertEqual(compressor.minimumBodySize, 512);
}

- (void)testCustomConfiguration {
    AFDeflateRequestCompressor *compressor = [[AFDeflateRequestCompressor alloc]
        initWithContentEncoding:AFContentEncodingGzip minimumBodySize:1024];
    XCTAssertEqual(compressor.contentEncoding, AFContentEncodingGzip);
    XCTAssertEqual(compressor.minimumBodySize, 1024);
}

#pragma mark - Compression

- (void)testDeflateCompressesData {
    AFDeflateRequestCompressor *compressor = [AFDeflateRequestCompressor defaultCompressor];
    NSData *original = [@"Hello, World! This is a test string that should be compressed." dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;

    NSData *compressed = [compressor compressData:original error:&error];

    XCTAssertNil(error);
    XCTAssertNotNil(compressed);
    XCTAssertGreaterThan(compressed.length, 0);
    // Compressed data should differ from original
    XCTAssertFalse([compressed isEqualToData:original]);
}

- (void)testGzipCompressesData {
    AFDeflateRequestCompressor *compressor = [AFDeflateRequestCompressor gzipCompressor];
    NSData *original = [@"Hello, World! This is a test string that should be compressed with gzip." dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;

    NSData *compressed = [compressor compressData:original error:&error];

    XCTAssertNil(error);
    XCTAssertNotNil(compressed);
    // Gzip data starts with magic bytes 0x1f 0x8b
    const uint8_t *bytes = compressed.bytes;
    XCTAssertEqual(bytes[0], 0x1f);
    XCTAssertEqual(bytes[1], 0x8b);
}

- (void)testCompressEmptyDataReturnsEmpty {
    AFDeflateRequestCompressor *compressor = [AFDeflateRequestCompressor defaultCompressor];
    NSData *empty = [NSData data];
    NSError *error = nil;

    NSData *result = [compressor compressData:empty error:&error];

    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertEqual(result.length, 0);
}

- (void)testDeflateCompressedDataIsDecompressible {
    AFDeflateRequestCompressor *compressor = [AFDeflateRequestCompressor defaultCompressor];
    NSString *originalString = @"The quick brown fox jumps over the lazy dog. Repeated for size. The quick brown fox jumps over the lazy dog.";
    NSData *original = [originalString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;

    NSData *compressed = [compressor compressData:original error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(compressed);

    // Decompress using raw inflate (matching raw deflate)
    z_stream stream;
    memset(&stream, 0, sizeof(stream));
    inflateInit2(&stream, -MAX_WBITS);

    NSMutableData *decompressed = [NSMutableData dataWithLength:original.length * 2];
    stream.next_in = (Bytef *)compressed.bytes;
    stream.avail_in = (uInt)compressed.length;
    stream.next_out = (Bytef *)decompressed.mutableBytes;
    stream.avail_out = (uInt)decompressed.length;

    int status = inflate(&stream, Z_FINISH);
    inflateEnd(&stream);

    XCTAssertEqual(status, Z_STREAM_END);
    decompressed.length = stream.total_out;
    XCTAssertEqualObjects(decompressed, original);
}

#pragma mark - Adapter Protocol

- (void)testAdapterSkipsSmallBody {
    AFDeflateRequestCompressor *compressor = [AFDeflateRequestCompressor defaultCompressor]; // min 512
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/post"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [@"small" dataUsingEncoding:NSUTF8StringEncoding]; // < 512 bytes

    XCTestExpectation *expectation = [self expectationWithDescription:@"adapter callback"];
    [compressor adaptRequest:request completion:^(NSURLRequest *adapted, NSError *error) {
        XCTAssertNil(error);
        // Should return original request unchanged (body < minimumBodySize)
        XCTAssertEqualObjects(adapted.HTTPBody, request.HTTPBody);
        XCTAssertNil([adapted valueForHTTPHeaderField:@"Content-Encoding"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testAdapterCompressesLargeBody {
    AFDeflateRequestCompressor *compressor = [[AFDeflateRequestCompressor alloc]
        initWithContentEncoding:AFContentEncodingDeflate minimumBodySize:10]; // low threshold
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/post"]];
    request.HTTPMethod = @"POST";

    // Create a body larger than minimumBodySize
    NSMutableString *largeString = [NSMutableString string];
    for (int i = 0; i < 100; i++) {
        [largeString appendString:@"Hello World! "];
    }
    request.HTTPBody = [largeString dataUsingEncoding:NSUTF8StringEncoding];

    XCTestExpectation *expectation = [self expectationWithDescription:@"adapter callback"];
    [compressor adaptRequest:request completion:^(NSURLRequest *adapted, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(adapted.HTTPBody);
        // Compressed body should be smaller
        XCTAssertLessThan(adapted.HTTPBody.length, request.HTTPBody.length);
        // Content-Encoding header should be set
        XCTAssertEqualObjects([adapted valueForHTTPHeaderField:@"Content-Encoding"], @"deflate");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testAdapterSkipsIfContentEncodingAlreadySet {
    AFDeflateRequestCompressor *compressor = [[AFDeflateRequestCompressor alloc]
        initWithContentEncoding:AFContentEncodingDeflate minimumBodySize:10];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/post"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [@"This body is large enough to compress normally" dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"adapter callback"];
    [compressor adaptRequest:request completion:^(NSURLRequest *adapted, NSError *error) {
        XCTAssertNil(error);
        // Should not re-compress — body unchanged
        XCTAssertEqualObjects(adapted.HTTPBody, request.HTTPBody);
        XCTAssertEqualObjects([adapted valueForHTTPHeaderField:@"Content-Encoding"], @"gzip");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testAdapterSkipsNilBody {
    AFDeflateRequestCompressor *compressor = [AFDeflateRequestCompressor defaultCompressor];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/get"]];
    request.HTTPMethod = @"GET";
    // No body

    XCTestExpectation *expectation = [self expectationWithDescription:@"adapter callback"];
    [compressor adaptRequest:request completion:^(NSURLRequest *adapted, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(adapted.HTTPBody);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testGzipAdapterSetsCorrectHeader {
    AFDeflateRequestCompressor *compressor = [[AFDeflateRequestCompressor alloc]
        initWithContentEncoding:AFContentEncodingGzip minimumBodySize:10];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://httpbin.org/post"]];
    request.HTTPMethod = @"POST";

    NSMutableString *body = [NSMutableString string];
    for (int i = 0; i < 50; i++) [body appendString:@"repeat data "];
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];

    XCTestExpectation *expectation = [self expectationWithDescription:@"gzip adapter"];
    [compressor adaptRequest:request completion:^(NSURLRequest *adapted, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects([adapted valueForHTTPHeaderField:@"Content-Encoding"], @"gzip");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
