import Foundation

/// 클로저 기반의 델리게이트 패턴을 구현한 유틸리티 클래스.
/// 클로저를 저장하고 호출하는 역할을 수행
/// 메모리 관리와 스레드 안정성을 고려하여 설계
/// Delegate는 클로저(block 또는 asyncBlock)를 저장하고, 필요할 때 호출
/// 입력(Input)을 받아 출력(Output)을 반환하는 클로저를 관리
public class Delegate<Input, Output>: @unchecked Sendable {
    // MARK: - Properties

    /// 스레드 안정성을 보장할 수있는 DispatchQueue를 사용하기 위해 이벤트 핸들링 구현 시, Delegate 클래스를 사용합니다.
    private let propertyQueue = DispatchQueue(label: "com.neon.NeoImage.DelegateQueue")

    /// 클로저(block 또는 asyncBlock)를 저장하고, 필요할 때 호출
    private var _block: ((Input) -> Output?)?
    /// 동기 클로저(block)와 비동기 클로저(asyncBlock)를 모두 지원
    private var _asyncBlock: ((Input) async -> Output?)?

    // MARK: - Computed Properties

    public var isSet: Bool {
        block != nil || asyncBlock != nil
    }

    private var block: ((Input) -> Output?)? {
        get { propertyQueue.sync { _block } }
        set { propertyQueue.sync { _block = newValue } }
    }

    private var asyncBlock: ((Input) async -> Output?)? {
        get { propertyQueue.sync { _asyncBlock } }
        set { propertyQueue.sync { _asyncBlock = newValue } }
    }

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Functions

    /// 클로저를 등록
    public func delegate<T: AnyObject>(on target: T, block: ((T, Input) -> Output)?) {
        self.block = { [weak target] input in
            guard let target else {
                return nil
            }
            return block?(target, input)
        }
    }

    public func delegate<T: AnyObject>(on target: T, block: ((T, Input) async -> Output)?) {
        asyncBlock = { [weak target] input in
            guard let target else {
                return nil
            }
            return await block?(target, input)
        }
    }

    /// 등록된 클로저를 호출
    public func call(_ input: Input) -> Output? {
        block?(input)
    }

    public func callAsFunction(_ input: Input) -> Output? {
        call(input)
    }

    public func callAsync(_ input: Input) async -> Output? {
        await asyncBlock?(input)
    }
}

extension Delegate where Input == Void {
    public func call() -> Output? {
        call(())
    }

    public func callAsFunction() -> Output? {
        call()
    }
}

extension Delegate where Input == Void, Output: OptionalProtocol {
    public func call() -> Output {
        call(())
    }

    public func callAsFunction() -> Output {
        call()
    }
}

extension Delegate where Output: OptionalProtocol {
    public func call(_ input: Input) -> Output {
        if let result = block?(input) {
            return result
        } else {
            return Output._createNil
        }
    }

    public func callAsFunction(_ input: Input) -> Output {
        call(input)
    }
}

public protocol OptionalProtocol {
    static var _createNil: Self { get }
}

/// Output이 Optional인 경우, nil을 반환하는 기능을 제공
extension Optional: OptionalProtocol {
    public static var _createNil: Optional<Wrapped> {
        nil
    }
}
