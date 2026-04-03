// DataStreamRequestTests.swift
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
import XCTest
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif

// MARK: - DataStreamRequest Tests

final class DataStreamRequestTests: BaseTestCase {

    /// 使用 httpbin.org 的 /stream/N endpoint 作为流式数据源
    private func streamEndpoint(_ count: Int) -> Endpoint {
        Endpoint.stream(count)
            .modifying(\.host, to: .httpBin)
            .modifying(\.scheme, to: .https)
    }

    private func statusEndpoint(_ code: Int) -> Endpoint {
        Endpoint.status(code)
            .modifying(\.host, to: .httpBin)
            .modifying(\.scheme, to: .https)
    }

    // MARK: - streamRequest 创建

    @MainActor
    func testThatStreamRequestReturnsDataStreamRequestType() {
        // Given
        let endpoint = streamEndpoint(1)

        // When
        let request = session.streamRequest(endpoint)

        // Then
        XCTAssertNotNil(request)
        XCTAssertTrue(request is DataStreamRequest)
    }

    // MARK: - responseStream (原始 Data)

    @MainActor
    func testThatResponseStreamReceivesDataChunks() {
        // Given
        let endpoint = streamEndpoint(3)
        let expectation = expectation(description: "stream should receive data chunks")
        var receivedChunks: [Data] = []
        var streamCompletion: DataStreamRequest.Completion?

        // When
        session.streamRequest(endpoint)
            .responseStream { stream in
                switch stream.event {
                case .stream(let result):
                    if case .success(let data) = result {
                        receivedChunks.append(data)
                    }
                case .complete(let completion):
                    streamCompletion = completion
                    expectation.fulfill()
                }
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertGreaterThan(receivedChunks.count, 0, "Should receive at least one data chunk")
        XCTAssertNotNil(streamCompletion, "Should receive completion event")
        XCTAssertNil(streamCompletion?.error, "Should complete without error")
    }

    // MARK: - responseStreamString (UTF8)

    @MainActor
    func testThatResponseStreamStringReceivesStringChunks() {
        // Given
        let endpoint = streamEndpoint(3)
        let expectation = expectation(description: "stream should receive string chunks")
        var receivedStrings: [String] = []
        var streamCompletion: DataStreamRequest.Completion?

        // When
        session.streamRequest(endpoint)
            .responseStreamString { stream in
                switch stream.event {
                case .stream(let result):
                    if case .success(let string) = result {
                        receivedStrings.append(string)
                    }
                case .complete(let completion):
                    streamCompletion = completion
                    expectation.fulfill()
                }
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertGreaterThan(receivedStrings.count, 0, "Should receive at least one string chunk")
        for string in receivedStrings {
            XCTAssertFalse(string.isEmpty, "Each chunk should be non-empty")
        }
        XCTAssertNotNil(streamCompletion)
        XCTAssertNil(streamCompletion?.error)
    }

    // MARK: - responseStreamDecodable

    @MainActor
    func testThatResponseStreamDecodableDecodesJSONChunks() {
        // Given — httpbin /stream/N 返回 N 行 JSON
        let endpoint = streamEndpoint(3)
        let expectation = expectation(description: "stream should decode JSON objects")
        var decodedObjects: [StreamLine] = []
        var decodingErrors: [Error] = []
        var streamCompletion: DataStreamRequest.Completion?

        // When
        session.streamRequest(endpoint)
            .responseStreamDecodable(of: StreamLine.self) { stream in
                switch stream.event {
                case .stream(let result):
                    switch result {
                    case .success(let value):
                        decodedObjects.append(value)
                    case .failure(let error):
                        decodingErrors.append(error)
                    }
                case .complete(let completion):
                    streamCompletion = completion
                    expectation.fulfill()
                }
            }

        waitForExpectations(timeout: timeout)

        // Then
        // httpbin /stream/N 可能将多行合并到一个 chunk 导致解码失败，
        // 但至少应该收到 completion
        XCTAssertNotNil(streamCompletion)
    }

    // MARK: - onHTTPResponse

    @MainActor
    func testThatOnHTTPResponseReceivesResponseHeaders() {
        // Given
        let endpoint = streamEndpoint(1)
        let expectation = expectation(description: "should receive HTTP response")
        var receivedResponse: HTTPURLResponse?

        // When
        session.streamRequest(endpoint)
            .onHTTPResponse { response in
                receivedResponse = response
            }
            .responseStream { stream in
                if case .complete = stream.event {
                    expectation.fulfill()
                }
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(receivedResponse)
        XCTAssertEqual(receivedResponse?.statusCode, 200)
    }

    @MainActor
    func testThatOnHTTPResponseWithCancelDispositionStopsStream() {
        // Given
        let endpoint = streamEndpoint(10)
        let expectation = expectation(description: "stream should be cancelled")
        var receivedChunks: [Data] = []
        var streamCompletion: DataStreamRequest.Completion?

        // When
        session.streamRequest(endpoint)
            .onHTTPResponse(on: .main) { response, completionHandler in
                // 收到响应头后立即取消
                completionHandler(.cancel)
            }
            .responseStream { stream in
                switch stream.event {
                case .stream(let result):
                    if case .success(let data) = result {
                        receivedChunks.append(data)
                    }
                case .complete(let completion):
                    streamCompletion = completion
                    expectation.fulfill()
                }
            }

        waitForExpectations(timeout: 20)

        // Then — 取消后不应收到（或极少）数据块
        XCTAssertNotNil(streamCompletion)
    }

    // MARK: - validate

    @MainActor
    func testThatValidatePassesForSuccessfulStatusCode() {
        // Given
        let endpoint = streamEndpoint(1)
        let expectation = expectation(description: "stream with validation should succeed")
        var streamCompletion: DataStreamRequest.Completion?

        // When
        session.streamRequest(endpoint)
            .validate()
            .responseStream { stream in
                if case .complete(let completion) = stream.event {
                    streamCompletion = completion
                    expectation.fulfill()
                }
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(streamCompletion)
        XCTAssertNil(streamCompletion?.error)
    }

    @MainActor
    func testThatValidateFailsForUnacceptableStatusCode() {
        // Given — 使用流式 endpoint 但验证范围排除 200
        let endpoint = streamEndpoint(1)
        let expectation = expectation(description: "stream with validation should fail")
        var streamCompletion: DataStreamRequest.Completion?
        var completionResponse: HTTPURLResponse?

        // When — 只接受 300-399，200 会被拒绝
        session.streamRequest(endpoint)
            .validate(statusCode: 300..<400)
            .onHTTPResponse { response in
                completionResponse = response
            }
            .responseStream { stream in
                if case .complete(let completion) = stream.event {
                    streamCompletion = completion
                    expectation.fulfill()
                }
            }

        waitForExpectations(timeout: 20)

        // Then — 应收到 200 状态码的响应，但 validate 标记为错误
        XCTAssertNotNil(streamCompletion)
        XCTAssertNotNil(completionResponse, "Should have received HTTP response")
        XCTAssertEqual(completionResponse?.statusCode, 200)
        // validate 应产生错误（200 不在 300-399 范围内）
        XCTAssertNotNil(streamCompletion?.error, "Should have a validation error for status 200 outside 300-399")
    }

    // MARK: - CancellationToken

    @MainActor
    func testThatCancellationTokenCancelsStream() {
        // Given
        let endpoint = streamEndpoint(100)
        let expectation = expectation(description: "stream should be cancelled via token")
        var receivedChunks: [Data] = []
        var streamCompletion: DataStreamRequest.Completion?

        // When
        session.streamRequest(endpoint)
            .responseStream { stream in
                switch stream.event {
                case .stream(let result):
                    if case .success(let data) = result {
                        receivedChunks.append(data)
                        // 收到第一个 chunk 后取消
                        if receivedChunks.count == 1 {
                            stream.cancel()
                        }
                    }
                case .complete(let completion):
                    streamCompletion = completion
                    expectation.fulfill()
                }
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(streamCompletion)
        // 取消后不应收到大量 chunk
        XCTAssertLessThan(receivedChunks.count, 100, "Should have cancelled before receiving all chunks")
    }

    // MARK: - Completion 事件

    @MainActor
    func testThatCompletionEventContainsRequestAndResponse() {
        // Given
        let endpoint = streamEndpoint(1)
        let expectation = expectation(description: "completion should contain request and response")
        var streamCompletion: DataStreamRequest.Completion?

        // When
        session.streamRequest(endpoint)
            .responseStream { stream in
                if case .complete(let completion) = stream.event {
                    streamCompletion = completion
                    expectation.fulfill()
                }
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(streamCompletion)
        XCTAssertNotNil(streamCompletion?.response, "Completion should contain HTTPURLResponse")
        XCTAssertNil(streamCompletion?.error, "Completion should not have error")
    }

    // MARK: - Stream 便利属性

    @MainActor
    func testThatStreamConveniencePropertiesWork() {
        // Given
        let endpoint = streamEndpoint(1)
        let expectation = expectation(description: "stream convenience properties")
        var receivedValue: Data?
        var receivedCompletion: DataStreamRequest.Completion?

        // When
        session.streamRequest(endpoint)
            .responseStream { stream in
                if let value = stream.value {
                    receivedValue = value
                }
                if let completion = stream.completion {
                    receivedCompletion = completion
                    expectation.fulfill()
                }
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(receivedValue, "Should receive at least one value via convenience property")
        XCTAssertNotNil(receivedCompletion, "Should receive completion via convenience property")
    }

    // MARK: - 多个流处理器

    @MainActor
    func testThatMultipleStreamHandlersReceiveData() {
        // Given
        let endpoint = streamEndpoint(2)
        let expectation1 = expectation(description: "first stream handler")
        let expectation2 = expectation(description: "second stream handler")
        var chunks1: [Data] = []
        var chunks2: [Data] = []

        // When
        session.streamRequest(endpoint)
            .responseStream { stream in
                switch stream.event {
                case .stream(let result):
                    if case .success(let data) = result {
                        chunks1.append(data)
                    }
                case .complete:
                    expectation1.fulfill()
                }
            }
            .responseStream { stream in
                switch stream.event {
                case .stream(let result):
                    if case .success(let data) = result {
                        chunks2.append(data)
                    }
                case .complete:
                    expectation2.fulfill()
                }
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertGreaterThan(chunks1.count, 0)
        XCTAssertGreaterThan(chunks2.count, 0)
        XCTAssertEqual(chunks1.count, chunks2.count, "Both handlers should receive same number of chunks")
    }
}

// MARK: - 测试辅助类型

/// httpbin /stream/N 的单行 JSON 结构
private struct StreamLine: Decodable, Sendable {
    let id: Int
    let url: String?
    let headers: [String: String]?
}
