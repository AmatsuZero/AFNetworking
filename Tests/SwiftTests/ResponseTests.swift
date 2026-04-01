//
//  ResponseTests.swift
//
//  Migrated from Alamofire/Tests/ResponseTests.swift
//  Retained: responseData, responseString, responseDecodable, response callbacks, map/tryMap/mapError.
//  Removed: Combine, DataStream, AFError-specific property checks not available in AFNetworkingSwift.
//

import Foundation
import XCTest
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif

final class ResponseTestCase: BaseTestCase {
    @MainActor
    func testThatResponseReturnsSuccessResultWithValidData() {
        // Given
        let expectation = expectation(description: "request should succeed")
        var response: DataResponse<Data?>?

        // When
        AF.request(Endpoint.default.urlString, parameters: ["foo": "bar"]).response { resp in
            response = resp
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.data)
        XCTAssertNil(response?.error)
        XCTAssertNotNil(response?.metrics)
    }

    @MainActor
    func testThatResponseReturnsFailureResultWithOptionalDataAndError() {
        // Given
        let invalidURL = String.invalidURL
        let expectation = expectation(description: "request should fail with invalid URL error")
        var response: DataResponse<Data?>?

        // When
        AF.request(invalidURL, parameters: ["foo": "bar"]).response { resp in
            response = resp
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNil(response?.response)
        XCTAssertNil(response?.data)
        XCTAssertNotNil(response?.error)
        XCTAssertNotNil(response?.metrics)
    }
}

// MARK: -

final class ResponseDataTestCase: BaseTestCase {
    @MainActor
    func testThatResponseDataReturnsSuccessResultWithValidData() {
        // Given
        let expectation = expectation(description: "request should succeed")
        var response: DataResponse<Data>?

        // When
        AF.request(Endpoint.default.urlString, parameters: ["foo": "bar"]).responseData { resp in
            response = resp
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.data)
        XCTAssertEqual(response?.result.isSuccess, true)
        XCTAssertNotNil(response?.metrics)
    }

    @MainActor
    func testThatResponseDataReturnsFailureResultWithOptionalDataAndError() {
        // Given
        let invalidURL = String.invalidURL
        let expectation = expectation(description: "request should fail with invalid URL error")
        var response: DataResponse<Data>?

        // When
        AF.request(invalidURL, parameters: ["foo": "bar"]).responseData { resp in
            response = resp
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNil(response?.response)
        XCTAssertNil(response?.data)
        XCTAssertEqual(response?.result.isFailure, true)
        XCTAssertNotNil(response?.error)
        XCTAssertNotNil(response?.metrics)
    }
}

// MARK: -

final class ResponseStringTestCase: BaseTestCase {
    @MainActor
    func testThatResponseStringReturnsSuccessResultWithValidString() {
        // Given
        let expectation = expectation(description: "request should succeed")
        var response: DataResponse<String>?

        // When
        AF.request(Endpoint.default.urlString, parameters: ["foo": "bar"]).responseString { resp in
            response = resp
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.data)
        XCTAssertEqual(response?.result.isSuccess, true)
        XCTAssertNotNil(response?.metrics)
    }

    @MainActor
    func testThatResponseStringReturnsFailureResultWithOptionalDataAndError() {
        // Given
        let invalidURL = String.invalidURL
        let expectation = expectation(description: "request should fail with invalid URL error")
        var response: DataResponse<String>?

        // When
        AF.request(invalidURL, parameters: ["foo": "bar"]).responseString { resp in
            response = resp
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNil(response?.response)
        XCTAssertNil(response?.data)
        XCTAssertEqual(response?.result.isFailure, true)
        XCTAssertNotNil(response?.error)
        XCTAssertNotNil(response?.metrics)
    }
}

// MARK: -

final class ResponseDecodableTestCase: BaseTestCase {
    @MainActor
    func testThatResponseDecodableReturnsSuccessResultWithValidJSON() {
        // Given
        let url = Endpoint.default.url
        let expectation = expectation(description: "request should succeed")
        var response: DataResponse<TestResponse>?

        // When
        AF.request(url.absoluteString, parameters: [:]).responseDecodable(of: TestResponse.self) { resp in
            response = resp
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.data)
        XCTAssertEqual(response?.result.isSuccess, true)
        XCTAssertNotNil(response?.metrics)
    }

    @MainActor
    func testThatResponseDecodableReturnsFailureResultWithError() {
        // Given
        let invalidURL = String.invalidURL
        let expectation = expectation(description: "request should fail")
        var response: DataResponse<TestResponse>?

        // When
        AF.request(invalidURL, parameters: [:]).responseDecodable(of: TestResponse.self) { resp in
            response = resp
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNil(response?.response)
        XCTAssertNil(response?.data)
        XCTAssertEqual(response?.result.isFailure, true)
        XCTAssertNotNil(response?.metrics)
    }
}
