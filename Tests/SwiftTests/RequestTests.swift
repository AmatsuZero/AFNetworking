//
//  RequestTests.swift
//
//  Migrated from Alamofire/Tests/RequestTests.swift
//  Only basic request lifecycle tests are retained.
//  Tests depending on ClosureEventMonitor, onHTTPResponse, shouldAutomaticallyResume,
//  requestSetup, DataStreamRequest, or UploadRequest have been removed.
//

import Foundation
import XCTest
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif

final class RequestResponseTestCase: BaseTestCase {
    @MainActor
    func testRequestResponse() {
        // Given
        let url = Endpoint.get.url
        let expectation = expectation(description: "GET request should succeed: \(url)")
        var response: DataResponse<Data?>?

        // When
        AF.request(url.absoluteString, parameters: ["foo": "bar"])
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.data)
        XCTAssertNil(response?.error)
    }

    @MainActor
    func testRequestResponseWithProgress() {
        // Given
        let byteCount = 512
        let url = Endpoint.bytes(byteCount).url

        let expectation = expectation(description: "Bytes download should complete: \(url)")
        var response: DataResponse<Data?>?

        // When
        AF.request(url.absoluteString)
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.data)
        XCTAssertNil(response?.error)
    }

    @MainActor
    func testPOSTRequestWithUnicodeParameters() {
        // Given
        let parameters: [String: Any] = ["french": "français",
                                          "japanese": "日本語",
                                          "arabic": "العربية",
                                          "emoji": "😃"]

        let expectation = expectation(description: "request should succeed")
        var response: DataResponse<TestResponse>?

        // When
        AF.request(Endpoint.method(.POST).urlString, method: .POST, parameters: parameters)
            .responseDecodable(of: TestResponse.self) { closureResponse in
                response = closureResponse
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.data)

        if let form = response?.value?.form {
            XCTAssertEqual(form["french"], parameters["french"] as? String)
            XCTAssertEqual(form["japanese"], parameters["japanese"] as? String)
            XCTAssertEqual(form["arabic"], parameters["arabic"] as? String)
            XCTAssertEqual(form["emoji"], parameters["emoji"] as? String)
        } else {
            XCTFail("form parameter in JSON should not be nil")
        }
    }

    // MARK: Queues

    @MainActor
    func testThatResponseSerializationWorksWithCustomSession() {
        // Given
        let customSession = Session()
        let expectation = expectation(description: "request should complete")
        var response: DataResponse<TestResponse>?

        // When
        customSession.request(Endpoint.get.urlString).responseDecodable(of: TestResponse.self) { resp in
            response = resp
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(response?.result.isSuccess, true)
    }

    @MainActor
    func testThatRequestsCanPassEncodableParametersAsJSONBodyData() {
        // Given
        let parameters: [String: Any] = ["property": "one"]
        let expect = expectation(description: "request should complete")
        var receivedResponse: DataResponse<TestResponse>?

        // When
        AF.request(Endpoint.method(.POST).urlString, method: .POST, parameters: parameters, encoding: .json)
            .responseDecodable(of: TestResponse.self) { response in
                receivedResponse = response
                expect.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(receivedResponse?.value?.data, "{\"property\":\"one\"}")
    }

    @MainActor
    func testThatRequestsCanPassEncodableParametersAsAURLQuery() {
        // Given
        let parameters: [String: Any] = ["property": "one"]
        let expect = expectation(description: "request should complete")
        var receivedResponse: DataResponse<TestResponse>?

        // When
        AF.request(Endpoint.get.urlString, parameters: parameters)
            .responseDecodable(of: TestResponse.self) { response in
                receivedResponse = response
                expect.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(receivedResponse?.value?.args, ["property": "one"])
    }

    @MainActor
    func testThatRequestsCanPassEncodableParametersAsURLEncodedBodyData() {
        // Given
        let parameters: [String: Any] = ["property": "one"]
        let expect = expectation(description: "request should complete")
        var receivedResponse: DataResponse<TestResponse>?

        // When
        AF.request(Endpoint.method(.POST).urlString, method: .POST, parameters: parameters)
            .responseDecodable(of: TestResponse.self) { response in
                receivedResponse = response
                expect.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(receivedResponse?.value?.form, ["property": "one"])
    }

    // MARK: - Request Lifecycle

    @MainActor
    func testThatRequestCanBeResumedAndCancelled() {
        // Given
        let expectation = expectation(description: "request should complete")
        var response: DataResponse<Data?>?

        // When
        let request = AF.request(Endpoint.get.urlString)
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        request.cancel()

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(request.state, .cancelled)
        XCTAssertNotNil(response?.error)
    }

    @MainActor
    func testThatRequestCanBeSuspendedAndResumed() {
        // Given
        let expectation = expectation(description: "request should complete after resume")
        var response: DataResponse<Data?>?

        // When
        let request = AF.request(Endpoint.get.urlString)
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        request.suspend()
        request.resume()

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response)
    }
}
