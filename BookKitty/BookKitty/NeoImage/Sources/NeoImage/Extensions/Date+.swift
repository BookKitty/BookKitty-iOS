import Foundation

extension Date {
    var isPast: Bool {
        isPast(referenceDate: Date())
    }

    func isPast(referenceDate: Date) -> Bool {
        timeIntervalSince(referenceDate) <= 0
    }

    /// `Date` in memory is a wrap for `TimeInterval`. But in file attribute it can only accept `Int` number.
    /// By default the system will `round` it. But it is not friendly for testing purpose.
    /// So we always `ceil` the value when used for file attributes.
    var fileAttributeDate: Date {
        Date(timeIntervalSince1970: ceil(timeIntervalSince1970))
    }
}
