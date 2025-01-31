import Foundation
@testable import Network
import RxSwift
import Testing

@Suite("Network Test", .serialized)
final class NetworkTests {
    // MARK: Lifecycle

    deinit {
        sut = nil
        MockURLProtocol.requestHandler = nil
    }

    // MARK: Internal

    let disposeBag = DisposeBag()
    var sut: NetworkManager!

    @Test
    func test_Request_성공_200() async {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: TestConstant.url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = try JSONEncoder().encode(TestConstant.dummyData)
            return (response, data)
        }

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        sut = NetworkManager(configuration: configuration)

        let endpoint = TestEndpoint()

        await withCheckedContinuation { continuation in
            sut.request(endpoint)
                .subscribe { response in
                    guard let response else {
                        #expect(Bool(false))
                        continuation.resume(returning: ())
                        return
                    }

                    #expect(response == TestConstant.dummyData)
                    continuation.resume(returning: ())
                } onFailure: { _ in
                    #expect(Bool(false))
                    continuation.resume(returning: ())
                }
                .disposed(by: disposeBag)
        }
    }

    @Test
    func test_Request_실패_404() async throws {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: TestConstant.url,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = try JSONEncoder().encode(TestConstant.dummyData)
            return (response, data)
        }

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        sut = NetworkManager(configuration: configuration)

        let endpoint = TestEndpoint()

        await withCheckedContinuation { continuation in
            sut.request(endpoint)
                .subscribe { _ in
                    #expect(Bool(false))
                    continuation.resume(returning: ())
                } onFailure: { error in
                    #expect(error as! NetworkError == NetworkError.clientError(404))
                    continuation.resume(returning: ())
                }
                .disposed(by: disposeBag)
        }
    }
}
