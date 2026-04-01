//
//  CacheTests.swift
//
//  Migrated from Alamofire/Tests/CacheTests.swift
//  Tests all implemented cache policies against various Cache-Control header values.
//

import Foundation
import XCTest
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif

/// This test case tests all implemented cache policies against various `Cache-Control` header values.
/// These tests work as follows:
///
/// - Set up a `URLCache`
/// - Set up a `Session`
/// - Execute requests for all `Cache-Control` header values to prime the `URLCache` with cached responses
/// - Start up a new test
/// - Execute another round of the same requests with a given `URLRequestCachePolicy`
/// - Verify whether the response came from the cache or from the network
///   - This is determined by whether the cached response timestamp matches the new response timestamp
final class CacheTestCase: BaseTestCase {
    // MARK: -

    enum CacheControl: String, CaseIterable {
        case publicControl = "public"
        case privateControl = "private"
        case maxAgeNonExpired = "max-age=3600"
        case maxAgeExpired = "max-age=0"
        case noCache = "no-cache"
        case noStore = "no-store"
    }

    // MARK: - Properties

    var urlCache: URLCache!
    var manager: Session!

    var requests: [CacheControl: URLRequest] = [:]
    var timestamps: [CacheControl: String] = [:]

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()

        urlCache = {
            let capacity = 50 * 1024 * 1024 // MBs
            #if targetEnvironment(macCatalyst)
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            return URLCache(memoryCapacity: capacity, diskCapacity: capacity, directory: directory)
            #else
            let directory = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString)
            return URLCache(memoryCapacity: capacity, diskCapacity: capacity, diskPath: directory)
            #endif
        }()

        manager = {
            let configuration: URLSessionConfiguration = {
                let configuration = URLSessionConfiguration.default
                configuration.requestCachePolicy = .useProtocolCachePolicy
                configuration.urlCache = urlCache
                return configuration
            }()
            return Session(configuration: configuration)
        }()

        primeCachedResponses()
    }

    override func tearDown() {
        super.tearDown()

        requests.removeAll()
        timestamps.removeAll()

        urlCache.removeAllCachedResponses()
    }

    // MARK: - Cache Priming Methods

    private func primeCachedResponses() {
        let dispatchGroup = DispatchGroup()
        let serialQueue = DispatchQueue(label: "org.afnetworking.cache-tests")

        for cacheControl in CacheControl.allCases {
            dispatchGroup.enter()

            let request = startRequest(cacheControl: cacheControl,
                                       queue: serialQueue,
                                       completion: { _, response in
                                           let timestamp = response?.allHeaderFields["Date"] as? String
                                           self.timestamps[cacheControl] = timestamp

                                           dispatchGroup.leave()
                                       })

            requests[cacheControl] = request
        }

        _ = dispatchGroup.wait(timeout: .now() + timeout)
    }

    // MARK: - Request Helper Methods

    @discardableResult
    private func startRequest(cacheControl: CacheControl,
                              cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                              queue: DispatchQueue = .main,
                              completion: @escaping @Sendable (URLRequest?, HTTPURLResponse?) -> Void)
        -> URLRequest {
        let endpoint = Endpoint(path: .cache,
                                timeout: 30,
                                queryItems: [.init(name: "Cache-Control", value: cacheControl.rawValue)],
                                cachePolicy: cachePolicy)
        let urlRequest = endpoint.urlRequest

        manager.request(urlRequest).response(queue: queue) { response in
            completion(response.request, response.response)
        }

        return urlRequest
    }

    // MARK: - Test Execution and Verification

    @MainActor
    private func executeTest(cachePolicy: URLRequest.CachePolicy,
                             cacheControl: CacheControl,
                             shouldReturnCachedResponse: Bool) {
        // Given
        let requestDidFinish = expectation(description: "cache test request did finish")
        var response: HTTPURLResponse?

        // When
        startRequest(cacheControl: cacheControl, cachePolicy: cachePolicy) { _, responseResponse in
            response = responseResponse
            requestDidFinish.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        verifyResponse(response, forCacheControl: cacheControl, isCachedResponse: shouldReturnCachedResponse)
    }

    private func verifyResponse(_ response: HTTPURLResponse?,
                                forCacheControl cacheControl: CacheControl,
                                isCachedResponse: Bool) {
        guard let cachedResponseTimestamp = timestamps[cacheControl] else {
            XCTFail("cached response timestamp should not be nil")
            return
        }

        if let response, let timestamp = response.allHeaderFields["Date"] as? String {
            if isCachedResponse {
                XCTAssertEqual(timestamp, cachedResponseTimestamp, "timestamps should be equal")
            } else {
                XCTAssertNotEqual(timestamp, cachedResponseTimestamp, "timestamps should not be equal")
            }
        } else {
            XCTFail("response should not be nil")
        }
    }

    // MARK: - Tests

    func testURLCacheContainsCachedResponsesForAllRequests() {
        // Given
        let publicRequest = requests[.publicControl]!
        let privateRequest = requests[.privateControl]!
        let maxAgeNonExpiredRequest = requests[.maxAgeNonExpired]!
        let maxAgeExpiredRequest = requests[.maxAgeExpired]!
        let noCacheRequest = requests[.noCache]!
        let noStoreRequest = requests[.noStore]!

        // When
        let publicResponse = urlCache.cachedResponse(for: publicRequest)
        let privateResponse = urlCache.cachedResponse(for: privateRequest)
        let maxAgeNonExpiredResponse = urlCache.cachedResponse(for: maxAgeNonExpiredRequest)
        let maxAgeExpiredResponse = urlCache.cachedResponse(for: maxAgeExpiredRequest)
        let noCacheResponse = urlCache.cachedResponse(for: noCacheRequest)
        let noStoreResponse = urlCache.cachedResponse(for: noStoreRequest)

        // Then
        XCTAssertNotNil(publicResponse, "\(CacheControl.publicControl) response should not be nil")
        XCTAssertNotNil(privateResponse, "\(CacheControl.privateControl) response should not be nil")
        XCTAssertNotNil(maxAgeNonExpiredResponse, "\(CacheControl.maxAgeNonExpired) response should not be nil")
        XCTAssertNotNil(maxAgeExpiredResponse, "\(CacheControl.maxAgeExpired) response should not be nil")
        XCTAssertNotNil(noCacheResponse, "\(CacheControl.noCache) response should not be nil")
        XCTAssertNil(noStoreResponse, "\(CacheControl.noStore) response should be nil")
    }

    @MainActor
    func testDefaultCachePolicy() {
        let cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy

        executeTest(cachePolicy: cachePolicy, cacheControl: .publicControl, shouldReturnCachedResponse: false)
        executeTest(cachePolicy: cachePolicy, cacheControl: .privateControl, shouldReturnCachedResponse: false)
        executeTest(cachePolicy: cachePolicy, cacheControl: .maxAgeNonExpired, shouldReturnCachedResponse: true)
        executeTest(cachePolicy: cachePolicy, cacheControl: .maxAgeExpired, shouldReturnCachedResponse: false)
        executeTest(cachePolicy: cachePolicy, cacheControl: .noCache, shouldReturnCachedResponse: false)
        executeTest(cachePolicy: cachePolicy, cacheControl: .noStore, shouldReturnCachedResponse: false)
    }

    @MainActor
    func testIgnoreLocalCacheDataPolicy() {
        let cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData

        executeTest(cachePolicy: cachePolicy, cacheControl: .publicControl, shouldReturnCachedResponse: false)
        executeTest(cachePolicy: cachePolicy, cacheControl: .privateControl, shouldReturnCachedResponse: false)
        executeTest(cachePolicy: cachePolicy, cacheControl: .maxAgeNonExpired, shouldReturnCachedResponse: false)
        executeTest(cachePolicy: cachePolicy, cacheControl: .maxAgeExpired, shouldReturnCachedResponse: false)
        executeTest(cachePolicy: cachePolicy, cacheControl: .noCache, shouldReturnCachedResponse: false)
        executeTest(cachePolicy: cachePolicy, cacheControl: .noStore, shouldReturnCachedResponse: false)
    }

    @MainActor
    func testUseLocalCacheDataIfExistsOtherwiseLoadFromNetworkPolicy() {
        let cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad

        executeTest(cachePolicy: cachePolicy, cacheControl: .publicControl, shouldReturnCachedResponse: true)
        executeTest(cachePolicy: cachePolicy, cacheControl: .privateControl, shouldReturnCachedResponse: true)
        executeTest(cachePolicy: cachePolicy, cacheControl: .maxAgeNonExpired, shouldReturnCachedResponse: true)
        executeTest(cachePolicy: cachePolicy, cacheControl: .maxAgeExpired, shouldReturnCachedResponse: true)
        executeTest(cachePolicy: cachePolicy, cacheControl: .noCache, shouldReturnCachedResponse: true)
        executeTest(cachePolicy: cachePolicy, cacheControl: .noStore, shouldReturnCachedResponse: false)
    }

    @MainActor
    func testUseLocalCacheDataAndDontLoadFromNetworkPolicy() {
        let cachePolicy: URLRequest.CachePolicy = .returnCacheDataDontLoad

        executeTest(cachePolicy: cachePolicy, cacheControl: .publicControl, shouldReturnCachedResponse: true)
        executeTest(cachePolicy: cachePolicy, cacheControl: .privateControl, shouldReturnCachedResponse: true)
        executeTest(cachePolicy: cachePolicy, cacheControl: .maxAgeNonExpired, shouldReturnCachedResponse: true)
        executeTest(cachePolicy: cachePolicy, cacheControl: .maxAgeExpired, shouldReturnCachedResponse: true)
        executeTest(cachePolicy: cachePolicy, cacheControl: .noCache, shouldReturnCachedResponse: true)

        // Given
        let requestDidFinish = expectation(description: "don't load from network request finished")
        var response: HTTPURLResponse?

        // When
        startRequest(cacheControl: .noStore, cachePolicy: cachePolicy) { _, responseResponse in
            response = responseResponse
            requestDidFinish.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(response, "response should be nil")
    }
}
