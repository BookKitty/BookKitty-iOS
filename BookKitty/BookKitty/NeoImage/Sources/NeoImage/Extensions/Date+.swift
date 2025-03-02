import Foundation

extension Date {
    var isPast: Bool {
        self < Date()
    }
}
