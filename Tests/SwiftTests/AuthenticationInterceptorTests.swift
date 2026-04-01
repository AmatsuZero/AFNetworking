// AuthenticationInterceptorTests.swift
// Migrated from Alamofire/Tests/AuthenticationInterceptorTests.swift
// Adapted for AFNetworkingSwift API differences.
//
// Key differences from Alamofire:
// - No validate()/AFDataResponse/AFError pattern matching
// - No ClosureEventMonitor (Combine-based EventMonitor)
// - RetryResult is a plain enum (no associated values for .doNotRetryWithError)
// - No refreshWindow/AuthenticationError.excessiveRefresh
// - Tests use adaptRequest(_:completion:) and shouldRetry(_:withError:retryCount:completion:) directly

import Foundation
import XCTest
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif

// MARK: - Helper Types

private struct TestCredential: AuthenticationCredential {
    let accessToken: String
    let refreshToken: String
    let userID: String
    let expiration: Date
    let requiresRefresh: Bool

    init(accessToken: String = "a0",
         refreshToken: String = "r0",
         userID: String = "u0",
         expiration: Date = Date(),
         requiresRefresh: Bool = false) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userID = userID
        self.expiration = expiration
        self.requiresRefresh = requiresRefresh
    }
}

private enum TestAuthError: Error, Equatable {
    case refreshNetworkFailure
}

private final class TestAuthenticator: Authenticator, @unchecked Sendable {
    private(set) var applyCount = 0
    private(set) var refreshCount = 0
    private let lock = NSLock()

    let shouldRefreshAsynchronously: Bool
    let refreshResult: Result<TestCredential, Error>?

    init(shouldRefreshAsynchronously: Bool = true,
         refreshResult: Result<TestCredential, Error>? = nil) {
        self.shouldRefreshAsynchronously = shouldRefreshAsynchronously
        self.refreshResult = refreshResult
    }

    func apply(_ credential: TestCredential, to urlRequest: inout URLRequest) {
        lock.lock(); defer { lock.unlock() }
        applyCount += 1
        urlRequest.setValue(credential.accessToken, forHTTPHeaderField: "Authorization")
    }

    func refresh(_ credential: TestCredential,
                 for session: Session,
                 completion: @escaping @Sendable (Result<TestCredential, Error>) -> Void) {
        lock.lock()
        refreshCount += 1
        let result = refreshResult ?? .success(
            TestCredential(accessToken: "a\(refreshCount)",
                           refreshToken: "r\(refreshCount)",
                           userID: "u1",
                           expiration: Date())
        )
        if shouldRefreshAsynchronously {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.01) {
                completion(result)
            }
            lock.unlock()
        } else {
            lock.unlock()
            completion(result)
        }
    }

    func didRequest(_ urlRequest: URLRequest,
                    with response: HTTPURLResponse,
                    failDueToAuthenticationError error: Error) -> Bool {
        response.statusCode == 401
    }

    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: TestCredential) -> Bool {
        urlRequest.value(forHTTPHeaderField: "Authorization") == credential.accessToken
    }
}

// MARK: - Result Box (avoids Sendable capture warnings for mutable vars)

private final class ResultBox<T>: @unchecked Sendable {
    var value: T?
    init() {}
}

// MARK: - AuthenticationInterceptorTests

final class AuthenticationInterceptorTests: BaseTestCase {

    // MARK: - adaptRequest - no credential

    func testThatAdaptPassesThroughRequestWhenCredentialIsNil() {
        // Given
        let authenticator = TestAuthenticator()
        let interceptor = AuthenticationInterceptor(authenticator: authenticator)
        let urlRequest = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let expect = expectation(description: "adapt completes")
        let box = ResultBox<URLRequest?>()

        // When
        interceptor.adaptRequest(urlRequest) { request, _ in
            box.value = request
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(box.value??.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(authenticator.applyCount, 0)
    }

    // MARK: - adaptRequest - valid credential

    func testThatAdaptAppliesCredentialWhenCredentialIsPresent() {
        // Given
        let credential = TestCredential()
        let authenticator = TestAuthenticator()
        let interceptor = AuthenticationInterceptor(authenticator: authenticator, credential: credential)
        let urlRequest = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let expect = expectation(description: "adapt completes")
        let box = ResultBox<URLRequest>()

        // When
        interceptor.adaptRequest(urlRequest) { request, _ in
            box.value = request
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(box.value?.value(forHTTPHeaderField: "Authorization"), "a0")
        XCTAssertEqual(authenticator.applyCount, 1)
        XCTAssertEqual(authenticator.refreshCount, 0)
    }

    // MARK: - adaptRequest - credential requires refresh

    func testThatAdaptTriggersRefreshWhenCredentialRequiresRefresh() {
        // Given
        let credential = TestCredential(requiresRefresh: true)
        let authenticator = TestAuthenticator()
        let interceptor = AuthenticationInterceptor(authenticator: authenticator, credential: credential)
        let urlRequest = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let expect = expectation(description: "adapt completes after refresh")
        let box = ResultBox<URLRequest>()

        // When
        interceptor.adaptRequest(urlRequest) { request, _ in
            box.value = request
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then - after refresh credential is a1
        XCTAssertEqual(box.value?.value(forHTTPHeaderField: "Authorization"), "a1")
        XCTAssertEqual(authenticator.refreshCount, 1)
        XCTAssertEqual(authenticator.applyCount, 1)
    }

    // MARK: - adaptRequest - refresh failure

    func testThatAdaptCallsCompletionWithErrorWhenRefreshFails() {
        // Given
        let credential = TestCredential(requiresRefresh: true)
        let authenticator = TestAuthenticator(refreshResult: .failure(TestAuthError.refreshNetworkFailure))
        let interceptor = AuthenticationInterceptor(authenticator: authenticator, credential: credential)
        let urlRequest = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let expect = expectation(description: "adapt completes with error")
        let errorBox = ResultBox<Error>()

        // When
        interceptor.adaptRequest(urlRequest) { _, error in
            errorBox.value = error
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(errorBox.value)
        XCTAssertEqual(errorBox.value as? TestAuthError, .refreshNetworkFailure)
        XCTAssertEqual(authenticator.refreshCount, 1)
        XCTAssertEqual(authenticator.applyCount, 0)
    }

    // MARK: - adaptRequest - multiple requests queue during refresh

    func testThatMultipleAdaptCallsQueueDuringRefresh() {
        // Given
        let credential = TestCredential(requiresRefresh: true)
        let authenticator = TestAuthenticator()
        let interceptor = AuthenticationInterceptor(authenticator: authenticator, credential: credential)
        let urlRequest = URLRequest(url: URL(string: "https://httpbin.org/get")!)

        let expect = expectation(description: "both adaptations complete")
        expect.expectedFulfillmentCount = 2
        let box1 = ResultBox<URLRequest>()
        let box2 = ResultBox<URLRequest>()

        // When - fire two adapt calls simultaneously while refresh is pending
        interceptor.adaptRequest(urlRequest) { request, _ in
            box1.value = request
            expect.fulfill()
        }
        interceptor.adaptRequest(urlRequest) { request, _ in
            box2.value = request
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then - both get the refreshed credential
        XCTAssertEqual(box1.value?.value(forHTTPHeaderField: "Authorization"), "a1")
        XCTAssertEqual(box2.value?.value(forHTTPHeaderField: "Authorization"), "a1")
        XCTAssertEqual(authenticator.refreshCount, 1)
        XCTAssertEqual(authenticator.applyCount, 2)
    }

    // MARK: - adaptRequest - synchronous refresh does not deadlock

    func testThatAdaptWithSynchronousRefreshDoesNotDeadlock() {
        // Given
        let credential = TestCredential(requiresRefresh: true)
        let authenticator = TestAuthenticator(shouldRefreshAsynchronously: false)
        let interceptor = AuthenticationInterceptor(authenticator: authenticator, credential: credential)
        let urlRequest = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let expect = expectation(description: "adapt completes synchronous refresh")
        let box = ResultBox<URLRequest>()

        // When
        interceptor.adaptRequest(urlRequest) { request, _ in
            box.value = request
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(box.value?.value(forHTTPHeaderField: "Authorization"), "a1")
        XCTAssertEqual(authenticator.refreshCount, 1)
    }

    // MARK: - shouldRetry - no credential

    func testThatShouldRetryReturnsDoNotRetryWhenCredentialIsNil() {
        // Given
        let authenticator = TestAuthenticator()
        let interceptor = AuthenticationInterceptor(authenticator: authenticator)
        let urlRequest = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let error = NSError(domain: ResponseValidationErrorDomain, code: 401, userInfo: nil)
        let expect = expectation(description: "shouldRetry completes")
        let box = ResultBox<RetryResult>()

        // When
        interceptor.shouldRetry(urlRequest, withError: error, retryCount: 0) { result, _ in
            box.value = result
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(box.value, .doNotRetry)
    }

    // MARK: - shouldRetry - max refresh count exceeded

    func testThatShouldRetryReturnsDoNotRetryWhenMaxRefreshCountExceeded() {
        // Given
        let credential = TestCredential()
        let authenticator = TestAuthenticator()
        let interceptor = AuthenticationInterceptor(authenticator: authenticator,
                                                    credential: credential,
                                                    maxRefreshCount: 0)
        let urlRequest = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let error = NSError(domain: ResponseValidationErrorDomain, code: 401, userInfo: nil)
        let expect = expectation(description: "shouldRetry completes")
        let box = ResultBox<RetryResult>()

        // When
        interceptor.shouldRetry(urlRequest, withError: error, retryCount: 0) { result, _ in
            box.value = result
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(box.value, .doNotRetry)
    }

    // MARK: - shouldRetry - non-auth error domain is not retried

    func testThatShouldRetryReturnsDoNotRetryForNonAuthErrorDomain() {
        // Given
        let credential = TestCredential()
        let authenticator = TestAuthenticator()
        let interceptor = AuthenticationInterceptor(authenticator: authenticator, credential: credential)
        let urlRequest = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let error = NSError(domain: "com.example.unrelated", code: 42, userInfo: nil)
        let expect = expectation(description: "shouldRetry completes")
        let box = ResultBox<RetryResult>()

        // When
        interceptor.shouldRetry(urlRequest, withError: error, retryCount: 0) { result, _ in
            box.value = result
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(box.value, .doNotRetry)
    }

    // MARK: - credential snapshot

    func testThatCredentialPropertyReflectsCurrentCredential() {
        // Given
        let credential = TestCredential(accessToken: "initial")
        let authenticator = TestAuthenticator()
        let interceptor = AuthenticationInterceptor(authenticator: authenticator, credential: credential)

        // Then
        XCTAssertEqual(interceptor.credential?.accessToken, "initial")
    }

    func testThatCredentialIsNilWhenNoCredentialProvided() {
        // Given
        let authenticator = TestAuthenticator()
        let interceptor = AuthenticationInterceptor(authenticator: authenticator)

        // Then
        XCTAssertNil(interceptor.credential)
    }

    // MARK: - Interceptor composition with AuthenticationInterceptor

    func testThatInterceptorCanBeComposedWithAdapterAndRetrier() {
        // Given
        let credential = TestCredential()
        let authenticator = TestAuthenticator()
        let authInterceptor = AuthenticationInterceptor(authenticator: authenticator, credential: credential)
        let compositeInterceptor = Interceptor(adapter: authInterceptor, retrier: authInterceptor)

        let urlRequest = URLRequest(url: URL(string: "https://httpbin.org/get")!)
        let expect = expectation(description: "composed interceptor adapt completes")
        let box = ResultBox<URLRequest>()

        // When
        compositeInterceptor.adaptRequest(urlRequest) { request, _ in
            box.value = request
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertEqual(box.value?.value(forHTTPHeaderField: "Authorization"), "a0")
        XCTAssertEqual(authenticator.applyCount, 1)
    }
}
