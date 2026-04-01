// SessionTests.swift
// 对齐 Alamofire SessionTests，验证 Session 的请求创建、响应处理和生命周期管理。

import XCTest
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif

final class SessionTests: BaseTestCase {

    // NOTE: This file is a legacy placeholder and will be replaced with Alamofire's SessionTests in Phase 3.

    // MARK: - 基本请求

    func testGETRequest() {
        let exp = expectation(description: "GET request should succeed")

        session.request("\(urlString)/get")
            .validate()
            .responseData { response in
                XCTAssertNotNil(response.value)
                XCTAssertNil(response.error)
                XCTAssertEqual(response.response?.statusCode, 200)
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }

    func testPOSTRequest() {
        let exp = expectation(description: "POST request should succeed")

        session.request("\(urlString)/post", method: .POST, parameters: ["key": "value"])
            .validate()
            .responseJSON { response in
                XCTAssertNotNil(response.value)
                XCTAssertNil(response.error)
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }

    func testPUTRequest() {
        let exp = expectation(description: "PUT request should succeed")

        session.request("\(urlString)/put", method: .PUT)
            .validate()
            .responseData { response in
                XCTAssertNil(response.error)
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }

    func testDELETERequest() {
        let exp = expectation(description: "DELETE request should succeed")

        session.request("\(urlString)/delete", method: .DELETE)
            .validate()
            .responseData { response in
                XCTAssertNil(response.error)
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }

    func testPATCHRequest() {
        let exp = expectation(description: "PATCH request should succeed")

        session.request("\(urlString)/patch", method: .PATCH)
            .validate()
            .responseData { response in
                XCTAssertNil(response.error)
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }

    // MARK: - 响应序列化

    func testResponseString() {
        let exp = expectation(description: "String response should succeed")

        session.request("\(urlString)/get")
            .validate()
            .responseString { response in
                XCTAssertNotNil(response.value)
                XCTAssertTrue(response.value?.contains("headers") == true)
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }

    func testResponseDecodable() {
        struct HTTPBinResponse: Decodable {
            let url: String
        }

        let exp = expectation(description: "Decodable response should succeed")

        session.request("\(urlString)/get")
            .validate()
            .responseDecodable(of: HTTPBinResponse.self) { response in
                XCTAssertNotNil(response.value)
                XCTAssertTrue(response.value?.url.contains("httpbin") == true)
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }

    // MARK: - 验证

    func testValidationWithAcceptableStatusCodes() {
        let exp = expectation(description: "Validation should pass for 200")

        session.request("\(urlString)/status/200")
            .validate(statusCode: 200..<300)
            .responseData { response in
                XCTAssertNil(response.error)
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }

    func testValidationWithUnacceptableStatusCode() {
        let exp = expectation(description: "Validation should fail for 404")

        session.request("\(urlString)/status/404")
            .validate(statusCode: 200..<300)
            .responseData { response in
                XCTAssertNotNil(response.error)
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }

    // MARK: - 请求取消

    func testCancelRequest() {
        let exp = expectation(description: "Cancelled request should fail")

        let request = session.request("\(urlString)/delay/5")
            .responseData { response in
                XCTAssertNotNil(response.error)
                exp.fulfill()
            }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            request.cancel()
        }

        waitForExpectations(timeout: timeout)
    }

    // MARK: - 自定义头

    func testCustomHeaders() {
        let exp = expectation(description: "Custom headers should be sent")

        let headers: HTTPHeaders = [
            HTTPHeader(name: "X-Custom-Header", value: "test-value")
        ]

        session.request("\(urlString)/headers", headers: headers)
            .validate()
            .responseJSON { response in
                if let json = response.value as? [String: Any],
                   let headers = json["headers"] as? [String: String] {
                    XCTAssertEqual(headers["X-Custom-Header"], "test-value")
                }
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }

    // MARK: - 默认 Session

    func testDefaultSession() {
        XCTAssertNotNil(Session.default)
        XCTAssertTrue(AF === Session.default)
    }
}
