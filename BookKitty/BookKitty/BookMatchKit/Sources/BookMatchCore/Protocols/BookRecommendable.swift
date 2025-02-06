import RxSwift
import UIKit

public protocol BookRecommendable {
    func recommendBooks(from ownedBooks: [OwnedBook]) async -> [BookItem]
    func recommendBooks(for question: String, from ownedBooks: [OwnedBook]) async
        -> BookMatchModuleOutput
}
