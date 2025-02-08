// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// 의존성을 관리하는 컨테이너 객체
/// ## 사용 예시
/// ```swift
/// // 의존성 등록
/// Container.register(YourViewController.self) {
///     YourViewController()
/// }
///
/// // 의존성 가져오기
/// let newVC = Container.resolve(YourViewController.self)
///
/// ```
/// ## 적절한 사용법
/// 각 객체 내부에서 객체의 의존성을 resolve하는 방식은 오히려 객체가 DI Container에 대한 의존성을 가지게 합니다.
/// 또한 객체가 어떤 의존성을 가지는지에 대한 정보를 숨기기 때문에 객체의 캡슐화를 깨뜨립니다.
/// ```swift
/// class SomeVC: UIViewController {
///     private let viewModel = Container.resolve(SomeViewModel.self)
/// }
///
/// let newVC = SomeVC() // SomeViewModel에 대한 의존성이 가려짐
/// ```
/// 따라서 책냥이 프로젝트에서는 아래와 같이 DI 방식으로 의존성을 관리하고자 합니다.
/// ```swift
/// class SomeVC: UIViewController {
///     private let viewModel: SomeViewModelProtocol
///
///     init(viewModel: SomeViewModelProtocol) {
///             self.viewModel = viewModel
///     }
/// }
///
/// Container.register(SomeViewModel.self) {
///     SomeViewModel()
/// }
/// let newVC = SomeVC(viewModel: Container.resolve(SomeViewModel.self))
/// ```
/// 이러한 예시는 단순히 서비스 로케이터 패턴으로의 사용과 의존성 주입 패턴으로의 사용을 비교하기 위한 단순 예시 입니다.
/// 뷰 컨트롤러까지 컨테이너에 register한 이후, 최종적으로 Coordinator에서 해당 VC만을 resolve해서 사용해도 됩니다.
///
/// ## 현 Container의 한계
/// 현재는 인자와 함께 register하는 API가 지원되지 않습니다.
///
/// ## 스레드 안정성
/// Container는 스레드 안전합니다. 다만 이는 함수 단위의 안정성이기 때문에, 원하는 결과를 정확히 얻기 위해서는 하나의 스레드 내부에서 순차적으로 실행하는 것이
/// 좋습니다.
///
/// ## MainActor
/// Swift 6 concurrency 안정성에 대응하기 위해 @MainActor를 사용하였습니다.
/// 이 부분은 추가적인 공부 이후 발전시켜나가겠습니다.
public final class Container: @unchecked Sendable {
    // MARK: - Static Properties

    // MARK: - Private

    /// 싱글톤 인스턴스
    private static let shared = Container()

    // MARK: - Properties

    /// 스레드 안전성을 위한 락 객체
    private let lock = NSLock()

    /// 서비스 타입과 구현을 저장하는 딕셔너리
    private var services: [String: Any] = [:]

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Static Functions

    // MARK: - Internal

    /// 서비스 타입과 구현을 등록하는 메서드
    /// - Parameters:
    ///   - service: 등록할 서비스의 타입
    ///   - implementation: 서비스 인스턴스를 생성하는 클로저
    static func register<Service>(
        _ service: Service.Type,
        _ implementation: @escaping () -> Service
    ) {
        shared.registerService(service, implementation)
    }

    /// 등록된 서비스를 조회하는 메서드
    /// - Parameter service: 조회할 서비스의 타입
    /// - Returns: 서비스 인스턴스. 등록되지 않은 경우 nil 반환
    static func resolve<Service>(_ service: Service.Type) -> Service? {
        shared.resolveService(service)
    }

    /// 등록된 모든 서비스를 제거하는 메서드
    static func removeAll() {
        shared.removeAllServices()
    }

    // MARK: - Functions

    /// 스레드 안전한 작업 수행을 위한 동기화 메서드
    /// - Parameter operation: 수행할 작업
    /// - Returns: 작업 결과
    private func synchronize<T>(_ operation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }

    /// 서비스 등록을 처리하는 내부 메서드
    /// - Parameters:
    ///   - service: 등록할 서비스의 타입
    ///   - implementation: 서비스 인스턴스를 생성하는 클로저
    private func registerService<T>(_ service: T.Type, _ implementation: @escaping () -> T) {
        synchronize {
            let serviceName = String(describing: service)
            services[serviceName] = implementation
        }
    }

    /// 서비스 조회를 처리하는 내부 메서드
    /// - Parameter service: 조회할 서비스의 타입
    /// - Returns: 서비스 인스턴스. 등록되지 않은 경우 nil 반환
    private func resolveService<T>(_ service: T.Type) -> T? {
        synchronize {
            let serviceName = String(describing: service)
            guard let implementation = services[serviceName] as? () -> T else {
                return nil
            }
            return implementation()
        }
    }

    /// 모든 서비스를 제거하는 내부 메서드
    private func removeAllServices() {
        synchronize {
            services.removeAll()
        }
    }
}
