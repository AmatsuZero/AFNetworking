// ValidationTests.swift
// 对齐 Alamofire ValidationTests，验证响应验证器的行为。

import XCTest
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
import AFSwiftSupport
#else
@testable import AFNetworking
#endif

final class ValidationTests: BaseTestCase {

    // MARK: - 状态码验证

    func testStatusCodeValidatorWithAcceptableCode() {
        let validator = StatusCodeValidator.`default`()
        let url = URL(string: "https://httpbin.org/get")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        let error = validator.validate(nil as URLRequest?, response: response, data: nil as Data?)
        XCTAssertNil(error)
    }

    func testStatusCodeValidatorWithUnacceptableCode() {
        let validator = StatusCodeValidator.`default`()
        let url = URL(string: "https://httpbin.org/get")!
        let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!

        let error = validator.validate(nil as URLRequest?, response: response, data: nil as Data?)
        XCTAssertNotNil(error)
    }

    func testStatusCodeValidatorWithCustomRange() {
        let validator = StatusCodeValidator(acceptableStatusCodes: IndexSet(integersIn: 200..<400))
        let url = URL(string: "https://httpbin.org/get")!
        let response = HTTPURLResponse(url: url, statusCode: 301, httpVersion: nil, headerFields: nil)!

        let error = validator.validate(nil as URLRequest?, response: response, data: nil as Data?)
        XCTAssertNil(error)
    }

    // MARK: - Content-Type 验证

    func testContentTypeValidatorWithAcceptableType() {
        let validator = ContentTypeValidator(acceptableContentTypes: Set(["application/json"]))
        let url = URL(string: "https://httpbin.org/get")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!

        let error = validator.validate(nil as URLRequest?, response: response, data: Data("{}".utf8))
        XCTAssertNil(error)
    }

    func testContentTypeValidatorWithUnacceptableType() {
        let validator = ContentTypeValidator(acceptableContentTypes: Set(["application/json"]))
        let url = URL(string: "https://httpbin.org/get")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "text/html"])!

        let error = validator.validate(nil as URLRequest?, response: response, data: Data("<html></html>".utf8))
        XCTAssertNotNil(error)
    }

    // MARK: - Block 验证

    func testBlockValidator() {
        let validator = BlockResponseValidator { (request: URLRequest?, response: HTTPURLResponse, data: Data?) -> NSError? in
            if response.statusCode == 418 {
                return NSError(domain: "test", code: 418, userInfo: [NSLocalizedDescriptionKey: "I'm a teapot"])
            }
            return nil
        }

        let url = URL(string: "https://httpbin.org/get")!
        let response418 = HTTPURLResponse(url: url, statusCode: 418, httpVersion: nil, headerFields: nil)!
        let response200 = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        XCTAssertNotNil(validator.validate(nil as URLRequest?, response: response418, data: nil as Data?))
        XCTAssertNil(validator.validate(nil as URLRequest?, response: response200, data: nil as Data?))
    }

    // MARK: - 链式验证

    func testChainedValidation() {
        let exp = expectation(description: "Chained validation should work")

        session.request("\(urlString)/get")
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData { response in
                XCTAssertNil(response.error)
                exp.fulfill()
            }

        waitForExpectations(timeout: timeout)
    }
}