// CombineTests.swift

#if canImport(Combine)
import Combine
import XCTest
@testable import AFNetworkingSwift

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class CombineTests: XCTestCase {

    // MARK: - DataResponsePublisher

    func testPublishDataReturnsPublisher() {
        let session = Session()
        let request = session.request("https://httpbin.org/get")
        let publisher = request.publishData()
        // Type check — DataResponsePublisher<Data>
        XCTAssertNotNil(publisher)
    }

    func testPublishStringReturnsPublisher() {
        let session = Session()
        let request = session.request("https://httpbin.org/get")
        let publisher = request.publishString()
        XCTAssertNotNil(publisher)
    }

    func testPublishDecodableReturnsPublisher() {
        struct Model: Decodable, Sendable { let url: String }
        let session = Session()
        let request = session.request("https://httpbin.org/get")
        let publisher = request.publishDecodable(type: Model.self)
        XCTAssertNotNil(publisher)
    }

    // MARK: - DownloadResponsePublisher

    func testDownloadPublishDataReturnsPublisher() {
        let session = Session()
        let request = session.download("https://httpbin.org/bytes/1024")
        let publisher = request.publishData()
        XCTAssertNotNil(publisher)
    }

    func testDownloadPublishDecodableReturnsPublisher() {
        struct Model: Decodable, Sendable { let url: String }
        let session = Session()
        let request = session.download("https://httpbin.org/get")
        let publisher = request.publishDecodable(type: Model.self)
        XCTAssertNotNil(publisher)
    }

    // MARK: - Value/Result convenience

    func testValuePublisherTypeCheck() {
        let session = Session()
        let request = session.request("https://httpbin.org/get")
        let publisher: AnyPublisher<Data, any Error> = request.publishData().value()
        XCTAssertNotNil(publisher)
    }

    func testResultPublisherTypeCheck() {
        let session = Session()
        let request = session.request("https://httpbin.org/get")
        let publisher: AnyPublisher<Result<Data, any Error>, Never> = request.publishData().result()
        XCTAssertNotNil(publisher)
    }

    // MARK: - Custom Serializer Publisher

    func testPublishResponseWithCustomSerializer() {
        let session = Session()
        let request = session.request("https://httpbin.org/get")
        let serializer = DataResponseSerializer()
        let publisher = request.publishResponse(using: serializer)
        XCTAssertNotNil(publisher)
    }

    // MARK: - NetworkReachabilityManager + Combine

    #if !os(watchOS)
    func testNetworkReachabilityPublisher() {
        let manager = NetworkReachabilityManager()
        let publisher = manager.publisher()
        XCTAssertNotNil(publisher)
        manager.stopListening()
    }
    #endif
}
#endif
