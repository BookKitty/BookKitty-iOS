@testable import DIContainer
import Foundation
import Testing

/// Container 클래스의 기능을 테스트하기 위한 테스트 스위트
@Suite
@MainActor
final class ContainerTests {
    // MARK: Lifecycle

    /// 인스턴스가 해제될 때 정리 작업을 수행합니다
    deinit {
        Container.removeAll()
    }

    // MARK: Internal

    /// 컨테이너 기능을 테스트하기 위한 목업 서비스 클래스
    class TestService {
        // MARK: Lifecycle

        /// value를 통해 TestService를 초기화합니다
        /// - Parameter value: 저장될 문자열 값
        init(value: String) {
            self.value = value
        }

        // MARK: Internal

        /// 저장된 문자열 값
        let value: String
    }

    /// 컨테이너에 서비스를 등록하고 가져오는 테스트
    @Test("Test Register and Resolve")
    func testRegisterAndResolve() async throws {
        // 특정 값을 가진 테스트 서비스를 등록합니다
        Container.register(TestService.self) {
            TestService(value: "test")
        }

        // 등록된 서비스를 해결하고 그 값을 검증합니다
        let resolved = Container.resolve(TestService.self)
        #expect(resolved?.value == "test")
    }

    /// 등록되지 않은 서비스를 가져오는 테스트
    @Test("Test Resolve without Register")
    func testRegisterAndResolveStruct() async throws {
        // 등록되지 않은 서비스를 해결하려고 시도합니다
        let resolved = Container.resolve(TestService.self)
        #expect(resolved == nil)
    }

    /// 컨테이너에서 모든 등록된 서비스를 제거하는 테스트
    @Test("Test remove all")
    func testRemoveAll() async throws {
        // 테스트 서비스를 등록합니다
        Container.register(TestService.self) {
            TestService(value: "testRemove")
        }

        // 모든 등록된 서비스를 제거합니다
        Container.removeAll()

        // 서비스가 더 이상 해결되지 않는지 확인합니다
        let resolved = Container.resolve(TestService.self)
        #expect(resolved == nil)
    }
}
