import Foundation

public actor Delegate<Input, Output> where Input: Sendable, Output: Sendable {
    // MARK: - Properties

    private var block: ((Input) -> Output?)?
    private var asyncBlock: ((Input) async -> Output?)?

    // MARK: - Computed Properties

    public var isSet: Bool {
        block != nil || asyncBlock != nil
    }

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Functions

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

extension Optional: OptionalProtocol {
    public static var _createNil: Optional<Wrapped> {
        nil
    }
}
