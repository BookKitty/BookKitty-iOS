import Foundation

extension Data: DataTransformable {
    public func toData() throws -> Data {
        self
    }

    public static func fromData(_ data: Data) throws -> Data {
        data
    }

    public static let empty = Data()
}
