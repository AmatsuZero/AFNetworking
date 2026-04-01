//
//  ValidationTests.swift
//
//  Migrated from Alamofire/Tests/ValidationTests.swift
//  Replaces the previous stub ValidationTests.swift.
//  Retained: status code validation, content-type validation, automatic validation, custom validation.
//  Note: AFNetworkingSwift validate closure returns Error? (not Result<Void, Error>).
//  Note: AFError properties (isUnacceptableStatusCode etc.) not available; use error != nil checks.
//

import Foundation
import XCTest
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif

final class StatusCodeValidationTestCase: BaseTestCase {
    @MainActor
    func testThatValidationForRequestWithAcceptableStatusCodeResponseSucceeds() {
        // Given
        let endpoint = Endpoint.status(200)

        let expectation1 = expectation(description: "request should return 200 status code")
        let expectation2 = expectation(description: "download should return 200 status code")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate(statusCode: 200..<300)
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate(statusCode: 200..<300)
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }

    @MainActor
    func testThatValidationForRequestWithUnacceptableStatusCodeResponseFails() {
        // Given
        let endpoint = Endpoint.status(404)

        let expectation1 = expectation(description: "request should return 404 status code")
        let expectation2 = expectation(description: "download should return 404 status code")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate(statusCode: [200])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate(statusCode: [200])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
    }

    @MainActor
    func testThatValidationForRequestWithNoAcceptableStatusCodesFails() {
        // Given
        let endpoint = Endpoint.status(201)

        let expectation1 = expectation(description: "request should return 201 status code")
        let expectation2 = expectation(description: "download should return 201 status code")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate(statusCode: [])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate(statusCode: [])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
    }
}

// MARK: -

final class ContentTypeValidationTestCase: BaseTestCase {
    @MainActor
    func testThatValidationForRequestWithAcceptableContentTypeResponseSucceeds() {
        // Given
        let endpoint = Endpoint.ip

        let expectation1 = expectation(description: "request should succeed and return ip")
        let expectation2 = expectation(description: "download should succeed and return ip")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate(contentType: ["application/json"])
            .validate(contentType: ["application/json; charset=utf-8"])
            .validate(contentType: ["application/json; q=0.8; charset=utf-8"])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate(contentType: ["application/json"])
            .validate(contentType: ["application/json; charset=utf-8"])
            .validate(contentType: ["application/json; q=0.8; charset=utf-8"])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }

    @MainActor
    func testThatValidationForRequestWithAcceptableWildcardContentTypeResponseSucceeds() {
        // Given
        let endpoint = Endpoint.ip

        let expectation1 = expectation(description: "request should succeed and return ip")
        let expectation2 = expectation(description: "download should succeed and return ip")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate(contentType: ["*/*"])
            .validate(contentType: ["application/*"])
            .validate(contentType: ["*/json"])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate(contentType: ["*/*"])
            .validate(contentType: ["application/*"])
            .validate(contentType: ["*/json"])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }

    @MainActor
    func testThatValidationForRequestWithUnacceptableContentTypeResponseFails() {
        // Given
        let endpoint = Endpoint.xml

        let expectation1 = expectation(description: "request should succeed and return xml")
        let expectation2 = expectation(description: "download should succeed and return xml")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate(contentType: ["application/octet-stream"])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate(contentType: ["application/octet-stream"])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
    }

    @MainActor
    func testThatValidationForRequestWithNoAcceptableContentTypeResponseFails() {
        // Given
        let endpoint = Endpoint.xml

        let expectation1 = expectation(description: "request should succeed and return xml")
        let expectation2 = expectation(description: "download should succeed and return xml")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate(contentType: [])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate(contentType: [])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
    }

    @MainActor
    func testThatValidationForRequestWithNoAcceptableContentTypeResponseSucceedsWhenNoDataIsReturned() {
        // Given
        let endpoint = Endpoint.status(204)

        let expectation1 = expectation(description: "request should succeed and return no data")
        let expectation2 = expectation(description: "download should succeed and return no data")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate(contentType: [])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate(contentType: [])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }
}

// MARK: -

final class MultipleValidationTestCase: BaseTestCase {
    @MainActor
    func testThatValidationForRequestWithAcceptableStatusCodeAndContentTypeResponseSucceeds() {
        // Given
        let endpoint = Endpoint.ip

        let expectation1 = expectation(description: "request should succeed and return ip")
        let expectation2 = expectation(description: "download should succeed and return ip")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }

    @MainActor
    func testThatValidationForRequestWithUnacceptableStatusCodeAndContentTypeResponseFails() {
        // Given
        let endpoint = Endpoint.xml

        let expectation1 = expectation(description: "request should succeed and return xml")
        let expectation2 = expectation(description: "download should succeed and return xml")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate(statusCode: 400..<600)
            .validate(contentType: ["application/octet-stream"])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate(statusCode: 400..<600)
            .validate(contentType: ["application/octet-stream"])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
    }
}

// MARK: -

final class AutomaticValidationTestCase: BaseTestCase {
    @MainActor
    func testThatValidationForRequestWithAcceptableStatusCodeAndContentTypeResponseSucceeds() {
        // Given
        var endpoint = Endpoint.ip
        endpoint.headers = [.accept("application/json")]

        let expectation1 = expectation(description: "request should succeed and return ip")
        let expectation2 = expectation(description: "download should succeed and return ip")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString, headers: endpoint.headers).validate().response { resp in
            requestError = resp.error
            expectation1.fulfill()
        }

        AF.download(endpoint.urlString, headers: endpoint.headers).validate().response { resp in
            downloadError = resp.error
            expectation2.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }

    @MainActor
    func testThatValidationForRequestWithUnacceptableStatusCodeResponseFails() {
        // Given
        let endpoint = Endpoint.status(404)

        let expectation1 = expectation(description: "request should return 404 status code")
        let expectation2 = expectation(description: "download should return 404 status code")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate()
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate()
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
    }

    @MainActor
    func testThatValidationForRequestWithAcceptableWildcardContentTypeResponseSucceeds() {
        // Given
        var endpoint = Endpoint.ip
        endpoint.headers = [.accept("application/*")]

        let expectation1 = expectation(description: "request should succeed and return ip")
        let expectation2 = expectation(description: "download should succeed and return ip")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString, headers: endpoint.headers).validate().response { resp in
            requestError = resp.error
            expectation1.fulfill()
        }

        AF.download(endpoint.urlString, headers: endpoint.headers).validate().response { resp in
            downloadError = resp.error
            expectation2.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }

    @MainActor
    func testThatValidationForRequestWithUnacceptableContentTypeResponseFails() {
        // Given
        var endpoint = Endpoint.xml
        endpoint.headers = [.accept("application/json")]

        let expectation1 = expectation(description: "request should succeed and return xml")
        let expectation2 = expectation(description: "download should succeed and return xml")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString, headers: endpoint.headers).validate().response { resp in
            requestError = resp.error
            expectation1.fulfill()
        }

        AF.download(endpoint.urlString, headers: endpoint.headers).validate().response { resp in
            downloadError = resp.error
            expectation2.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
    }
}

// MARK: -

private enum ValidationError: Error {
    case missingData, missingFile, fileReadFailed
}

final class CustomValidationTestCase: BaseTestCase {
    @MainActor
    func testThatCustomValidationClosureHasAccessToServerResponseData() {
        // Given
        let endpoint = Endpoint.default

        let expectation1 = expectation(description: "request should return 200 status code")
        let expectation2 = expectation(description: "download should return 200 status code")

        var requestError: Error?
        var downloadError: Error?

        // When
        // Note: AFNetworkingSwift validate closure returns Error? (nil = success)
        AF.request(endpoint.urlString)
            .validate { _, _, data in
                guard data != nil else { return ValidationError.missingData }
                return nil
            }
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate { _, _, data in
                guard data != nil else { return ValidationError.missingFile }
                return nil
            }
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }

    @MainActor
    func testThatCustomValidationCanReturnCustomError() {
        // Given
        let endpoint = Endpoint.default

        let expectation1 = expectation(description: "request should return validation error")
        let expectation2 = expectation(description: "download should return validation error")

        var requestError: Error?
        var downloadError: Error?

        // When
        AF.request(endpoint.urlString)
            .validate { _, _, _ in ValidationError.missingData }
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
            }

        AF.download(endpoint.urlString)
            .validate { _, _, _ in ValidationError.missingFile }
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
        XCTAssertTrue(requestError is ValidationError)
        XCTAssertTrue(downloadError is ValidationError)
    }
}
