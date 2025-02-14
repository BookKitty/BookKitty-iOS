//
//  NetworkManager.swift
//  Network
//
//  Created by 권승용 on 1/28/25.
//

import Foundation
import RxSwift

/// 네트워크 기능을 수행하는 객체
public final class NetworkManager: NetworkManageable {
    // MARK: - Static Properties

    // MARK: - Public

    public static let shared = NetworkManager()

    // MARK: - Properties

    // MARK: - Private

    private let session: URLSession

    // MARK: - Lifecycle

    init(configuration: URLSessionConfiguration = .default) {
        session = URLSession(configuration: configuration)
    }

    // MARK: - Functions

    public func request<T: Endpoint>(_ endpoint: T) -> Single<T.Response?> {
        Single.create { observer in
            // 전달받은 Endpoint로 request 생성
            guard let request = self.createRequest(from: endpoint, observer: observer) else {
                return Disposables.create()
            }

            let task = self.session.dataTask(with: request) { data, response, error in
                // 에러 체크
                if let error {
                    observer(.failure(error))
                    return
                }

                // URLResponse -> HTTPURLResponse 타입 캐스팅
                guard let response = self.typeCastResponse(
                    data: data,
                    response: response,
                    observer: observer,
                    T.self
                ) else {
                    return
                }

                self.handleResponse(data: data, response: response, observer: observer, T.self)
            }
            task.resume()
            return Disposables.create()
        }
    }
}

// MARK: - Private

extension NetworkManager {
    /// request 생성
    private func createRequest<T: Endpoint>(
        from endpoint: T,
        observer: (Result<T.Response?, any Error>) -> Void
    ) -> URLRequest? {
        guard let request = endpoint.toRequest() else {
            observer(.failure(NetworkError.invalidURL))
            return nil
        }

        NetworkEventLogger.requestDidFinish(request)

        return request
    }

    private func typeCastResponse<T: Endpoint>(
        data: Data?,
        response: URLResponse?,
        observer: (Result<T.Response?, any Error>) -> Void,
        _: T.Type
    ) -> HTTPURLResponse? {
        guard let response = response as? HTTPURLResponse else {
            observer(.failure(NetworkError.responseTypeCastingFailed))
            return nil
        }

        NetworkEventLogger.responseDidFinish(data, response)

        return response
    }

    /// response 처리
    private func handleResponse<T: Endpoint>(
        data: Data?,
        response: HTTPURLResponse,
        observer: (Result<T.Response?, any Error>) -> Void,
        _: T.Type
    ) {
        // status code에 따른 Result<Void, Error> 타입 반환
        let managedResult = handleStatusCode(response)
        switch managedResult {
        // 200~299 범위 벗어나면 error 방출
        case let .failure(error):
            observer(.failure(error))
        case .success:
            // data nil인 경우 처리
            guard let data else {
                // 응답은 잘 수행되었지만 데이터가 없는 경우 고려
                observer(.success(nil))
                return
            }
            // Data 타입인 경우 디코딩 없이 바로 반환
            if T.Response.self == Data.self {
                observer(.success(data as? T.Response))
                return
            }

            // data에 값이 있는 경우 디코딩 수행
            guard let responseData = try? JSONDecoder().decode(T.Response.self, from: data)
            else {
                observer(.failure(NetworkError.decodingFailed))
                return
            }
            // 값 전달
            observer(.success(responseData))
        }
    }
}

// MARK: - Handle Status code

extension NetworkManager {
    /// 응답 스테이터스 코드에 따른 예외처리
    private func handleStatusCode(_ response: HTTPURLResponse) -> Result<Void, Error> {
        let code = response.statusCode
        switch code {
        case 100 ..< 200:
            return .failure(NetworkError.informationalError(code))
        case 200 ..< 300:
            return .success(())
        case 300 ..< 400:
            return .failure(NetworkError.redirectionError(code))
        case 400 ..< 500:
            return .failure(NetworkError.clientError(code))
        case 500 ..< 600:
            return .failure(NetworkError.serverError(code))
        default:
            return .failure(NetworkError.unknownError(code))
        }
    }
}
