import UIKit

public protocol BookMatchable {
    func recommendBooks(from ownedBooks: [OwnedBook]) async -> [BookItem]
    func recommendBooks(for input: BookMatchModuleInput) async -> BookMatchModuleOutput
    func matchBook(_ rawData: [[String]], image: UIImage) async -> BookItem?
}
