// RetryPolicyTests.swift

import XCTest
@testable import AFNetworkingSwift
import AFNetworking

final class RetryPolicyTests: XCTestCase {

    // MARK: - Default RetryPolicy

    func testDefaultRetryPolicyProperties() {
        let policy = RetryPolicy()
        XCTAssertEqual(policy.retryLimit, 2)
        XCTAssertEqual(policy.exponentialBackoffBase, 2.0)
        XCTAssertEqual(policy.exponentialBackoffScale, 0.5)
        XCTAssertTrue(policy.retryableHTTPMethods.contains("GET"))
        XCTAssertTrue(policy.retryableHTTPMethods.contains("PUT"))
        XCTAssertFalse(policy.retryableHTTPMethods.contains("POST"))
    }

    func testCustomRetryPolicyProperties() {
        let policy = RetryPolicy(retryLimit: 5,
                                  exponentialBackoffBase: 3.0,
                                  exponentialBackoffScale: 1.0)
        XCTAssertEqual(policy.retryLimit, 5)
        XCTAssertEqual(policy.exponentialBackoffBase, 3.0)
        XCTAssertEqual(policy.exponentialBackoffScale, 1.0)
    }

    // MARK: - Retry Decision

    func testRetriesOnNetworkError() {
        let policy = RetryPolicy()
        let request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)

        let expectation = expectation(description: "retry decision")
        policy.shouldRetry(request, withError: error, retryCount: 0) { result, _ in
            if case .retryWithDelay(let delay) = result {
                // delay = pow(2, 0) * 0.5 = 0.5
                XCTAssertEqual(delay, 0.5, accuracy: 0.01)
            } else {
                XCTFail("Expected retryWithDelay, got \(result)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testDoNotRetryWhenLimitExceeded() {
        let policy = RetryPolicy(retryLimit: 2)
        let request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)

        let expectation = expectation(description: "no retry")
        policy.shouldRetry(request, withError: error, retryCount: 2) { result, _ in
            if case .doNotRetry = result {
                // Expected
            } else {
                XCTFail("Expected doNotRetry, got \(result)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testDoNotRetryForNonRetryableError() {
        let policy = RetryPolicy()
        let request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL)

        let expectation = expectation(description: "no retry for bad URL")
        policy.shouldRetry(request, withError: error, retryCount: 0) { result, _ in
            if case .doNotRetry = result {
                // Expected — BadURL is not in retryable codes
            } else {
                XCTFail("Expected doNotRetry, got \(result)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - Exponential Backoff

    func testExponentialBackoffDelay() {
        let policy = RetryPolicy(retryLimit: 5, exponentialBackoffBase: 2.0, exponentialBackoffScale: 0.5)
        // delay = pow(2, retryCount) * 0.5
        XCTAssertEqual(policy.storage.retryDelay(forRetryCount: 0), 0.5, accuracy: 0.01)  // 2^0 * 0.5
        XCTAssertEqual(policy.storage.retryDelay(forRetryCount: 1), 1.0, accuracy: 0.01)  // 2^1 * 0.5
        XCTAssertEqual(policy.storage.retryDelay(forRetryCount: 2), 2.0, accuracy: 0.01)  // 2^2 * 0.5
        XCTAssertEqual(policy.storage.retryDelay(forRetryCount: 3), 4.0, accuracy: 0.01)  // 2^3 * 0.5
    }

    // MARK: - ConnectionLostRetryPolicy

    func testConnectionLostRetryPolicyRetriesOnConnectionLost() {
        let policy = ConnectionLostRetryPolicy()
        let request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)

        let expectation = expectation(description: "retry on connection lost")
        policy.shouldRetry(request, withError: error, retryCount: 0) { result, _ in
            if case .retryWithDelay = result {
                // Expected
            } else {
                XCTFail("Expected retryWithDelay, got \(result)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testConnectionLostRetryPolicyDoNotRetryOnTimeout() {
        let policy = ConnectionLostRetryPolicy()
        let request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)

        let expectation = expectation(description: "no retry on timeout")
        policy.shouldRetry(request, withError: error, retryCount: 0) { result, _ in
            if case .doNotRetry = result {
                // Expected — ConnectionLost only retries on connection lost
            } else {
                XCTFail("Expected doNotRetry, got \(result)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - Adapter passthrough

    func testRetryPolicyAdapterPassthrough() {
        let policy = RetryPolicy()
        let request = URLRequest(url: URL(string: "https://httpbin.org/get")!)

        let expectation = expectation(description: "adapter passthrough")
        policy.adaptRequest(request) { adapted, error in
            XCTAssertNil(error)
            XCTAssertEqual(adapted?.url, request.url)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - OC Layer

    func testAFRetryPolicyDefaultOC() {
        let ocPolicy = AFRetryPolicy.default()
        XCTAssertEqual(ocPolicy.retryLimit, 2)
        XCTAssertEqual(ocPolicy.exponentialBackoffBase, 2.0)
        XCTAssertEqual(ocPolicy.exponentialBackoffScale, 0.5)
    }

    func testAFConnectionLostRetryPolicyOC() {
        let ocPolicy = AFConnectionLostRetryPolicy.default()
        XCTAssertEqual(ocPolicy.retryLimit, 2)
        // Should not retry on timeout — only on connection lost
        let request = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        XCTAssertFalse(ocPolicy.shouldRetry(request, response: nil, withError: timeoutError))

        let connLostError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)
        XCTAssertTrue(ocPolicy.shouldRetry(request, response: nil, withError: connLostError))
    }
}
