// ResponseSerializerTests.swift

import XCTest
@testable import AFNetworkingSwift

final class ResponseSerializerTests: XCTestCase {

    // MARK: - DataResponseSerializer

    func testDataResponseSerializerSuccess() throws {
        let serializer = DataResponseSerializer()
        let data = "hello".data(using: .utf8)!
        let result = try serializer.serialize(request: nil, response: makeResponse(200), data: data, error: nil)
        XCTAssertEqual(result, data)
    }

    func testDataResponseSerializerEmptyDataThrows() {
        let serializer = DataResponseSerializer()
        XCTAssertThrowsError(
            try serializer.serialize(request: nil, response: makeResponse(200), data: nil, error: nil)
        )
    }

    func testDataResponseSerializerEmptyStatusCode() throws {
        let serializer = DataResponseSerializer()
        let result = try serializer.serialize(request: nil, response: makeResponse(204), data: nil, error: nil)
        XCTAssertEqual(result, Data())
    }

    func testDataResponseSerializerPropagatesError() {
        let serializer = DataResponseSerializer()
        let error = NSError(domain: "test", code: 1)
        XCTAssertThrowsError(
            try serializer.serialize(request: nil, response: nil, data: nil, error: error)
        )
    }

    // MARK: - StringResponseSerializer

    func testStringResponseSerializerSuccess() throws {
        let serializer = StringResponseSerializer()
        let data = "hello world".data(using: .utf8)!
        let result = try serializer.serialize(request: nil, response: makeResponse(200), data: data, error: nil)
        XCTAssertEqual(result, "hello world")
    }

    func testStringResponseSerializerEmptyStatusCode() throws {
        let serializer = StringResponseSerializer()
        let result = try serializer.serialize(request: nil, response: makeResponse(204), data: nil, error: nil)
        XCTAssertEqual(result, "")
    }

    func testStringResponseSerializerEmptyDataThrows() {
        let serializer = StringResponseSerializer()
        XCTAssertThrowsError(
            try serializer.serialize(request: nil, response: makeResponse(200), data: nil, error: nil)
        )
    }

    // MARK: - DecodableResponseSerializer

    func testDecodableResponseSerializerSuccess() throws {
        struct Model: Decodable, Sendable, Equatable {
            let name: String
        }

        let serializer = DecodableResponseSerializer<Model>()
        let json = #"{"name":"test"}"#
        let data = json.data(using: .utf8)!
        let result = try serializer.serialize(request: nil, response: makeResponse(200), data: data, error: nil)
        XCTAssertEqual(result.name, "test")
    }

    func testDecodableResponseSerializerEmptyResponseWithEmptyType() throws {
        let serializer = DecodableResponseSerializer<Empty>()
        let result = try serializer.serialize(request: nil, response: makeResponse(204), data: nil, error: nil)
        // Empty conforms to EmptyResponse, should succeed
        XCTAssertNotNil(result)
    }

    func testDecodableResponseSerializerInvalidJSON() {
        struct Model: Decodable, Sendable {
            let name: String
        }

        let serializer = DecodableResponseSerializer<Model>()
        let data = "not json".data(using: .utf8)!
        XCTAssertThrowsError(
            try serializer.serialize(request: nil, response: makeResponse(200), data: data, error: nil)
        )
    }

    // MARK: - DataPreprocessor

    func testPassthroughPreprocessor() throws {
        let preprocessor = PassthroughPreprocessor()
        let data = "test".data(using: .utf8)!
        let result = try preprocessor.preprocess(data)
        XCTAssertEqual(result, data)
    }

    func testGoogleXSSIPreprocessor() throws {
        let preprocessor = GoogleXSSIPreprocessor()
        let json = #"{"key":"value"}"#
        let xssiData = (")]}\'\n" + json).data(using: .utf8)!
        let result = try preprocessor.preprocess(xssiData)
        XCTAssertEqual(String(data: result, encoding: .utf8), json)
    }

    // MARK: - Helpers

    private func makeResponse(_ statusCode: Int) -> HTTPURLResponse? {
        HTTPURLResponse(url: URL(string: "https://httpbin.org")!,
                        statusCode: statusCode,
                        httpVersion: "HTTP/1.1",
                        headerFields: nil)
    }
}
