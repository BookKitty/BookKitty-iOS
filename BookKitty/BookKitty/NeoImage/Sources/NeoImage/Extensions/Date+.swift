import Foundation

extension Date {
    var isPast: Bool {
        return self < Date()
    }
}
