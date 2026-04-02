// RequestCompressionTests.swift

import XCTest
@testable import AFNetworkingSwift
import AFNetworking

final class RequestCompressionTests: XCTestCase {

    // MARK: - Default Properties

    func testDefaultCompressorProperties() {
        let compressor = DeflateRequestCompressor.default
        XCTAssertEqual(compressor.contentEncoding, .deflate)
        XCTAssertEqual(compressor.minimumBodySize, 512)
    }

    func testGzipCompressorProperties() {
        let compressor = DeflateRequestCompressor.gzip
        XCTAssertEqual(compressor.contentEncoding, .gzip)
        XCTAssertEqual(compressor.minimumBodySize, 512)
    }

    func testCustomConfiguration() {
        let compressor = DeflateRequestCompressor(contentEncoding: .gzip, minimumBodySize: 1024)
        XCTAssertEqual(compressor.contentEncoding, .gzip)
        XCTAssertEqual(compressor.minimumBodySize, 1024)
    }

    // MARK: - OC Layer Compression

    func testDeflateCompressesData() throws {
        let compressor = AFDeflateRequestCompressor.default()
        let original = Data(repeating: 65, count: 1000) // 1000 bytes of 'A'

        let compressed = try compressor.compressData(original)
        XCTAssertNotNil(compressed)
        XCTAssertLessThan(compressed.count, original.count)
    }

    func testGzipCompressedDataHasMagicHeader() throws {
        let compressor = AFDeflateRequestCompressor.gzip()
        let original = Data(repeating: 66, count: 1000)

        let compressed = try compressor.compressData(original)
        XCTAssertGreaterThanOrEqual(compressed.count, 2)
        // Gzip magic bytes: 0x1f 0x8b
        XCTAssertEqual(compressed[0], 0x1f)
        XCTAssertEqual(compressed[1], 0x8b)
    }

    func testCompressEmptyDataReturnsEmpty() throws {
        let compressor = AFDeflateRequestCompressor.default()
        let result = try compressor.compressData(Data())
        XCTAssertEqual(result.count, 0)
    }

    // MARK: - Adapter Behavior (Swift Wrapper)

    func testAdapterSkipsSmallBody() {
        let compressor = DeflateRequestCompressor.default // min 512 bytes
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        request.httpBody = Data("small".utf8) // < 512

        let expectation = expectation(description: "adapter skips small body")
        compressor.adaptRequest(request) { adapted, error in
            XCTAssertNil(error)
            XCTAssertEqual(adapted?.httpBody, request.httpBody)
            XCTAssertNil(adapted?.value(forHTTPHeaderField: "Content-Encoding"))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testAdapterCompressesLargeBody() {
        let compressor = DeflateRequestCompressor(contentEncoding: .deflate, minimumBodySize: 10)
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        let body = Data(repeating: 72, count: 1000) // 1000 bytes of 'H'
        request.httpBody = body

        let expectation = expectation(description: "adapter compresses large body")
        compressor.adaptRequest(request) { adapted, error in
            XCTAssertNil(error)
            XCTAssertNotNil(adapted?.httpBody)
            XCTAssertLessThan(adapted!.httpBody!.count, body.count)
            XCTAssertEqual(adapted?.value(forHTTPHeaderField: "Content-Encoding"), "deflate")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testGzipAdapterSetsCorrectHeader() {
        let compressor = DeflateRequestCompressor(contentEncoding: .gzip, minimumBodySize: 10)
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        request.httpBody = Data(repeating: 65, count: 500)

        let expectation = expectation(description: "gzip header set")
        compressor.adaptRequest(request) { adapted, error in
            XCTAssertNil(error)
            XCTAssertEqual(adapted?.value(forHTTPHeaderField: "Content-Encoding"), "gzip")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testAdapterSkipsIfContentEncodingAlreadySet() {
        let compressor = DeflateRequestCompressor(contentEncoding: .deflate, minimumBodySize: 10)
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        request.httpBody = Data(repeating: 65, count: 500)
        request.setValue("br", forHTTPHeaderField: "Content-Encoding")

        let expectation = expectation(description: "skip already encoded")
        compressor.adaptRequest(request) { adapted, error in
            XCTAssertNil(error)
            // Body should remain unchanged
            XCTAssertEqual(adapted?.httpBody, request.httpBody)
            XCTAssertEqual(adapted?.value(forHTTPHeaderField: "Content-Encoding"), "br")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testAdapterSkipsNilBody() {
        let compressor = DeflateRequestCompressor.default
        var request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        request.httpMethod = "GET"

        let expectation = expectation(description: "skip nil body")
        compressor.adaptRequest(request) { adapted, error in
            XCTAssertNil(error)
            XCTAssertNil(adapted?.httpBody)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - RequestRetrier (passthrough)

    func testRetrierAlwaysReturnsDoNotRetry() {
        let compressor = DeflateRequestCompressor.default
        let request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)

        let expectation = expectation(description: "retrier returns doNotRetry")
        compressor.shouldRetry(request, withError: error, retryCount: 0) { result, _ in
            XCTAssertEqual(result, .doNotRetry)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
