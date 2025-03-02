import Foundation

/// Sendable 프로토콜을 채택하여 동시성 환경에서 안전하게 사용 가능합니다.
public protocol DataTransformable: Sendable {
    /// Converts the current value to a `Data` representation.
    /// - Returns: The data object which can represent the value of the conforming type.
    /// - Throws: If any error happens during the conversion.
    func toData() throws -> Data

    /// Convert some data to the value.
    /// - Parameter data: The data object which should represent the conforming value.
    /// - Returns: The converted value of the conforming type.
    /// - Throws: If any error happens during the conversion.
    static func fromData(_ data: Data) throws -> Self

    /// An empty object of `Self`.
    ///
    /// > In the cache, when the data is not actually loaded, this value will be returned as a
    /// placeholder.
    /// > This variable should be returned quickly without any heavy operation inside.
    static var empty: Self { get }
}
