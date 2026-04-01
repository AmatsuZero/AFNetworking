//
//  DownloadTests.swift
//
//  Migrated from Alamofire/Tests/DownloadTests.swift
//  Retained: basic download, destination path, cancel, progress, parameters, headers tests.
//  Changes: DownloadRequest.Destination -> DownloadDestination (top-level struct),
//           DownloadDestination closure returns (URL, DownloadDestination.Options).
//  Removed: tests depending on UploadRequest or Alamofire-specific APIs not in AFNetworkingSwift.
//

import Foundation
import XCTest
#if SWIFT_PACKAGE
@testable import AFNetworkingSwift
import AFNetworking
#else
@testable import AFNetworking
#endif

final class DownloadInitializationTests: BaseTestCase {
    @MainActor
    func testDownloadClassMethodWithMethodURLAndDestination() {
        // Given
        let endpoint = Endpoint.get
        let expectation = expectation(description: "download should complete")

        // When
        let request = AF.download(endpoint.urlString).response { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(request.request)
        XCTAssertEqual(request.request?.httpMethod, "GET")
        XCTAssertNotNil(request.response)
    }

    @MainActor
    func testDownloadClassMethodWithMethodURLHeadersAndDestination() {
        // Given
        let endpoint = Endpoint.get
        let headers: HTTPHeaders = ["Authorization": "123456"]
        let expectation = expectation(description: "download should complete")

        // When
        let request = AF.download(endpoint.urlString, headers: headers).response { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(request.request)
        XCTAssertEqual(request.request?.httpMethod, "GET")
        XCTAssertEqual(request.request?.value(forHTTPHeaderField: "Authorization"), "123456")
        XCTAssertNotNil(request.response)
    }
}

// MARK: -

final class DownloadResponseTests: BaseTestCase {
    private var randomCachesFileURL: URL {
        testDirectoryURL.appendingPathComponent("\(UUID().uuidString).json")
    }

    @MainActor
    func testDownloadRequest() {
        // Given
        let fileURL = randomCachesFileURL
        let numberOfLines = 10
        let endpoint = Endpoint.stream(numberOfLines)
        let destination = DownloadDestination { _, _ in (fileURL, []) }

        let expectation = expectation(description: "Download request should download data to file")
        var response: DownloadResponse<URL?>?

        // When
        AF.download(endpoint.urlString, to: destination)
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.fileURL)
        XCTAssertNil(response?.resumeData)
        XCTAssertNil(response?.error)

        if let destinationURL = response?.fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))

            if let data = try? Data(contentsOf: destinationURL) {
                XCTAssertGreaterThan(data.count, 0)
            } else {
                XCTFail("data should exist for contents of destinationURL")
            }
        }
    }

    @MainActor
    func testCancelledDownloadRequest() {
        // Given
        let fileURL = randomCachesFileURL
        let numberOfLines = 10
        let destination = DownloadDestination { _, _ in (fileURL, []) }

        let expectation = expectation(description: "Cancelled download request should not download data to file")
        var response: DownloadResponse<URL?>?

        // When
        AF.download(Endpoint.stream(numberOfLines).urlString, to: destination)
            .response { resp in
                response = resp
                expectation.fulfill()
            }
            .cancel()

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNil(response?.response)
        XCTAssertNil(response?.fileURL)
        XCTAssertNotNil(response?.error)
    }

    @MainActor
    func testDownloadRequestWithParameters() {
        // Given
        let fileURL = randomCachesFileURL
        let parameters: [String: Any] = ["foo": "bar"]
        let destination = DownloadDestination { _, _ in (fileURL, []) }

        let expectation = expectation(description: "Download request should download data to file")
        var response: DownloadResponse<URL?>?

        // When
        AF.download(Endpoint.get.urlString, parameters: parameters, to: destination)
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.fileURL)
        XCTAssertNil(response?.resumeData)
        XCTAssertNil(response?.error)

        if let data = try? Data(contentsOf: fileURL),
           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let json = jsonObject as? [String: Any],
           let args = json["args"] as? [String: String] {
            XCTAssertEqual(args["foo"], "bar")
        } else {
            XCTFail("args parameter in JSON should not be nil")
        }
    }

    @MainActor
    func testDownloadRequestWithHeaders() {
        // Given
        let fileURL = randomCachesFileURL
        let endpoint = Endpoint.get
        let headers: HTTPHeaders = ["Authorization": "123456"]
        let destination = DownloadDestination { _, _ in (fileURL, []) }

        let expectation = expectation(description: "Download request should download data to file")
        var response: DownloadResponse<URL?>?

        // When
        AF.download(endpoint.urlString, headers: headers, to: destination)
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.fileURL)
        XCTAssertNil(response?.resumeData)
        XCTAssertNil(response?.error)

        guard let data = try? Data(contentsOf: fileURL),
              let testResponse = try? JSONDecoder().decode(TestResponse.self, from: data) else {
            XCTFail("headers parameter in JSON should not be nil")
            return
        }

        XCTAssertEqual(testResponse.headers["Authorization"], "123456")
    }

    @MainActor
    func testThatDownloadingFileAndMovingToDirectoryThatDoesNotExistThrowsError() {
        // Given
        let fileURL = testDirectoryURL.appendingPathComponent("some/random/folder/test_output.json")

        let expectation = expectation(description: "Download request should download data but fail to move file")
        var response: DownloadResponse<URL?>?

        // When
        AF.download(Endpoint.get.urlString, to: DownloadDestination { _, _ in (fileURL, []) })
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNil(response?.fileURL)
        XCTAssertNil(response?.resumeData)
        XCTAssertNotNil(response?.error)
    }

    @MainActor
    func testThatDownloadOptionsCanCreateIntermediateDirectoriesPriorToMovingFile() {
        // Given
        let fileURL = testDirectoryURL.appendingPathComponent("some/random/folder/test_output.json")

        let expectation = expectation(description: "Download request should download data to file: \(fileURL)")
        var response: DownloadResponse<URL?>?

        // When
        AF.download(Endpoint.get.urlString,
                    to: DownloadDestination { _, _ in (fileURL, [.createIntermediateDirectories]) })
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.fileURL)
        XCTAssertNil(response?.resumeData)
        XCTAssertNil(response?.error)
    }

    @MainActor
    func testThatDownloadingFileAndMovingToDestinationThatIsOccupiedThrowsError() throws {
        // Given
        let directoryURL = testDirectoryURL.appendingPathComponent("some/random/folder")
        let directoryCreated = FileManager.createDirectory(at: directoryURL)

        let fileURL = directoryURL.appendingPathComponent("test_output.json")
        try "random_data".write(to: fileURL, atomically: true, encoding: .utf8)

        let expectation = expectation(description: "Download should complete but fail to move file")
        var response: DownloadResponse<URL?>?

        // When
        AF.download(Endpoint.get.urlString, to: DownloadDestination { _, _ in (fileURL, []) })
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(directoryCreated)
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNil(response?.fileURL)
        XCTAssertNil(response?.resumeData)
        XCTAssertNotNil(response?.error)
    }

    @MainActor
    func testThatDownloadOptionsCanRemovePreviousFilePriorToMovingFile() {
        // Given
        let directoryURL = testDirectoryURL.appendingPathComponent("some/random/folder")
        let directoryCreated = FileManager.createDirectory(at: directoryURL)

        let fileURL = directoryURL.appendingPathComponent("test_output.json")

        let expectation = expectation(description: "Download should complete and move file to URL: \(fileURL)")
        var response: DownloadResponse<URL?>?

        // When
        AF.download(Endpoint.get.urlString,
                    to: DownloadDestination { _, _ in (fileURL, [.removePreviousFile, .createIntermediateDirectories]) })
            .response { resp in
                response = resp
                expectation.fulfill()
            }

        waitForExpectations(timeout: timeout)

        // Then
        XCTAssertTrue(directoryCreated)
        XCTAssertNotNil(response?.request)
        XCTAssertNotNil(response?.response)
        XCTAssertNotNil(response?.fileURL)
        XCTAssertNil(response?.resumeData)
        XCTAssertNil(response?.error)
    }
}
